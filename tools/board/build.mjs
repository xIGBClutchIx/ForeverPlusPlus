#!/usr/bin/env node
// Builds the data files behind the Forever++ Board artifact (tools/board/index.html): the issues
// and requests with where each stands, every commit with the release it shipped in, the release
// notes, and each release's diffs. Reads git, CHANGELOG.md, GitHub (the gh CLI), CurseForge's
// public comment feed, and, when it's there, the inbox task's state file.
//
//   node tools/board/build.mjs [--out <dir>] [--state <file>] [--branch main] [--force]
//   node tools/board/build.mjs --published
//
// Writes <out>/data/*.json (out/ by default, which git ignores) and prints, after CHANGED, the
// files that differ from what was last published, so only those need publishing with
// index.html. Run it with --published once a publish went through, to record that. A released
// version's diffs never change, so its file is written once (--force writes them all again). Needs Node 20 or newer, git, and gh signed in; with
// GitHub or CurseForge unreachable it keeps what the last run read from them.
import { execFileSync } from 'node:child_process';
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '..', '..');
const args = process.argv.slice(2);
const opt = (name, fallback) => {
    const i = args.indexOf('--' + name);
    return i >= 0 && args[i + 1] ? args[i + 1] : fallback;
};
const out = path.resolve(opt('out', path.join(here, 'out')));
const dataDir = path.join(out, 'data');
const statePath = opt('state', path.join(os.homedir(), '.claude', 'fpp-inbox-state.json'));
const BRANCH = opt('branch', 'main');
const FORCE = args.includes('--force');

const CF_PROJECT = 1714613;
const CF_URL = 'https://www.curseforge.com/wow/addons/foreverplusplus/comments';
const UNRELEASED = 'Unreleased';
const WIP = 'In progress';
const MAX_PATCH = 80000; // bytes of one file's diff kept; a longer one is cut at a line
const MAX_TEXT = 2400; // letters of a request's or reply's text kept
// Generated data: counted in a commit's numbers, but its diff is left out.
const GENERATED = [
    'ForeverPlusPlus/Lib/Generated',
    'ForeverPlusPlus/Modules/Map/WorldMap/UnexploredAreas/Data.lua',
    'ForeverPlusPlus/Modules/Character/Professions/Data.lua',
    'tools/datagen/Reference.txt',
    'docs/table-survey.md',
];

fs.mkdirSync(dataDir, { recursive: true });
const manifestPath = path.join(out, 'manifest.json'); // what the files on disk hold
const publishedPath = path.join(out, 'published.json'); // what the artifact holds
if (args.includes('--published')) {
    fs.copyFileSync(manifestPath, publishedPath);
    console.log('Recorded the files on disk as published.');
    process.exit(0);
}

function run(cmd, a) {
    return execFileSync(cmd, a, {
        cwd: repo, encoding: 'utf8', maxBuffer: 1024 ** 3, stdio: ['ignore', 'pipe', 'pipe'],
    });
}
const git = (...a) => run('git', a);
const lines = (text) => text.split('\n').map((l) => l.trim()).filter(Boolean);
const clip = (text, max = MAX_TEXT) => {
    text = String(text || '').replace(/\r/g, '').trim();
    return text.length > max ? text.slice(0, max).trimEnd() + ' ...' : text;
};
const isGenerated = (p) => GENERATED.some((g) => p === g || p.startsWith(g + '/'));

// Git: releases and commits -------------------------------------------------------------------

const tags = lines(git('tag', '-l', 'v*'))
    .map((tag) => ({ tag, depth: Number(git('rev-list', '--count', tag).trim()) }))
    .sort((a, b) => a.depth - b.depth);

// "dir/{old => new}/file" and "old => new", as numstat writes a rename, to the new path.
function newPath(p) {
    return p.replace(/\{(.*?) => (.*?)\}/g, '$2').replace(/^.* => /, '').replace(/\/\//g, '/');
}

const commits = new Map(); // sha -> commit, in every release and branch read
function readCommits(range, release, branch) {
    const text = git('log', '--no-merges', '--numstat', '-M',
        '--format=%x01%H%x02%aI%x02%an%x02%s%x02%b%x03', range);
    const list = [];
    for (const chunk of text.split('\x01').slice(1)) {
        const [head, tail = ''] = chunk.split('\x03');
        const [sha, date, author, subject, body = ''] = head.split('\x02');
        if (commits.has(sha)) { continue; }
        const files = [];
        for (const line of tail.split('\n')) {
            const m = /^(\d+|-)\t(\d+|-)\t(.+)$/.exec(line);
            if (m) {
                files.push({ path: newPath(m[3]), adds: Number(m[1]) || 0, dels: Number(m[2]) || 0, binary: m[1] === '-' });
            }
        }
        const cc = /^(\w+)(?:\(([^)]+)\))?!?:\s*(.+)$/.exec(subject);
        const refs = [...new Set([...(subject + '\n' + body).matchAll(/#(\d+)\b/g)].map((m) => Number(m[1])))];
        const commit = {
            sha, date, author, subject, release, branch,
            type: cc ? cc[1].toLowerCase() : 'other', scope: cc ? cc[2] || '' : '',
            summary: cc ? cc[3] : subject, refs, files,
            adds: files.reduce((n, f) => n + f.adds, 0), dels: files.reduce((n, f) => n + f.dels, 0),
        };
        commits.set(sha, commit);
        list.push(commit);
    }
    return list;
}

const releases = []; // oldest first, then Unreleased
let prev = null;
for (const { tag } of tags) {
    const range = prev ? prev + '..' + tag : tag;
    releases.push({ version: tag.slice(1), tag, range, prev, commits: readCommits(range, tag.slice(1)) });
    prev = tag;
}
const head = git('rev-parse', BRANCH).trim();
const unreleasedRange = prev ? prev + '..' + BRANCH : BRANCH;
releases.push({ version: UNRELEASED, tag: null, range: unreleasedRange, prev, commits: readCommits(unreleasedRange, UNRELEASED) });

// The author with the most commits is the project's own: only others' names are kept, as credit.
const byAuthor = new Map();
for (const c of commits.values()) { byAuthor.set(c.author, (byAuthor.get(c.author) || 0) + 1); }
const ownName = [...byAuthor].sort((a, b) => b[1] - a[1])[0]?.[0];

let unpushed = new Set();
try { unpushed = new Set(lines(git('rev-list', 'origin/' + BRANCH + '..' + BRANCH))); } catch { /* no remote */ }

// The inbox task's state: which request each branch and commit is for.
let inbox = { dispatched: {} };
try { inbox = JSON.parse(fs.readFileSync(statePath, 'utf8')); } catch { /* not on this machine */ }
const dispatched = inbox.dispatched || {};

// Branches not merged yet. Only a branch a request was handed to gets its commits read.
const branches = [];
const wanted = new Set(Object.values(dispatched).map((d) => d.branch).filter(Boolean));
const wip = { version: WIP, commits: [] };
for (const line of lines(git('for-each-ref', '--format=%(refname:short)%09%(committerdate:iso-strict)%09%(subject)', 'refs/heads'))) {
    const [name, date, subject] = line.split('\t');
    if (name === BRANCH) { continue; }
    const ahead = Number(git('rev-list', '--count', BRANCH + '..' + name).trim());
    if (!ahead) { continue; }
    branches.push({ name, ahead, date, subject });
    if (wanted.has(name) && ahead <= 60) {
        wip.commits.push(...readCommits(BRANCH + '..' + name, WIP, name));
    }
}
branches.sort((a, b) => (a.date < b.date ? 1 : -1));

function findCommit(prefix) {
    if (!prefix || prefix.length < 7) { return null; }
    if (commits.has(prefix)) { return prefix; }
    for (const sha of commits.keys()) { if (sha.startsWith(prefix)) { return sha; } }
    return null;
}

// Diffs ---------------------------------------------------------------------------------------

function readPatches(range) {
    const exclude = GENERATED.map((g) => ':(exclude)' + g);
    const text = git('log', '-p', '--no-merges', '-M', '--no-color', '--no-ext-diff',
        '--format=%x01%H', range, '--', '.', ...exclude);
    const bySha = new Map();
    for (const chunk of text.split('\x01').slice(1)) {
        const parts = chunk.split(/^diff --git /m);
        const sha = parts[0].trim();
        const files = new Map();
        for (const part of parts.slice(1)) {
            const at = part.search(/^@@ /m);
            const header = at >= 0 ? part.slice(0, at) : part;
            const to = /^\+\+\+ b\/(.+)$/m.exec(header) || /^rename to (.+)$/m.exec(header)
                || /^--- a\/(.+)$/m.exec(header) || /^a\/.+ b\/(.+)$/m.exec(header);
            if (!to) { continue; }
            const from = /^rename from (.+)$/m.exec(header);
            let status = 'changed';
            if (/^new file mode/m.test(header)) { status = 'added'; }
            else if (/^deleted file mode/m.test(header)) { status = 'deleted'; }
            else if (from) { status = 'renamed'; }
            let patch = at >= 0 ? part.slice(at).replace(/\n+$/, '') : '';
            let cut = false;
            if (patch.length > MAX_PATCH) {
                patch = patch.slice(0, patch.lastIndexOf('\n', MAX_PATCH));
                cut = true;
            }
            files.set(to[1].trim(), { status, from: from ? from[1].trim() : undefined, patch, cut });
        }
        bySha.set(sha, files);
    }
    return bySha;
}

function patchFile(release) {
    const patches = release.commits.length ? readPatches(release.range) : new Map();
    const result = {};
    for (const c of release.commits) {
        const diffs = patches.get(c.sha) || new Map();
        result[c.sha] = c.files.map((f) => {
            const d = diffs.get(f.path);
            const entry = { path: f.path, adds: f.adds, dels: f.dels, status: d ? d.status : 'changed' };
            if (d && d.from) { entry.from = d.from; }
            if (d && d.patch) { entry.patch = d.patch; if (d.cut) { entry.cut = true; } }
            else if (isGenerated(f.path)) { entry.note = 'generated'; }
            else if (f.binary) { entry.note = 'binary'; }
            else { entry.note = 'moved'; }
            return entry;
        });
    }
    return { version: release.version, commits: result };
}

// Release notes -------------------------------------------------------------------------------

const notes = new Map(); // version -> { date, sections: [{ heading, entries: [{ name, text }] }] }
{
    let current = null;
    let section = null;
    for (const line of fs.readFileSync(path.join(repo, 'CHANGELOG.md'), 'utf8').split(/\r?\n/)) {
        const release = /^## (\S+)(?: \((\d{4}-\d{2}-\d{2})\))?/.exec(line);
        const heading = /^### (.+)$/.exec(line);
        const entry = /^- (.+)$/.exec(line);
        if (release) {
            current = { date: release[2] || null, sections: [] };
            section = null;
            notes.set(release[1], current);
        } else if (heading && current) {
            section = { heading: heading[1].trim(), entries: [] };
            current.sections.push(section);
        } else if (entry && section) {
            const named = /^((?:\*\*[^*]+\*\*(?:, )?)+): (.+)$/.exec(entry[1]);
            section.entries.push(named
                ? { name: named[1].replace(/\*\*/g, ''), text: named[2] }
                : { name: '', text: entry[1] });
        }
    }
}

// GitHub and CurseForge -----------------------------------------------------------------------

const cachePath = path.join(out, 'sources.json');
let cache = {};
try { cache = JSON.parse(fs.readFileSync(cachePath, 'utf8')); } catch { /* first run */ }
const sources = {};

function fromSource(name, read) {
    try {
        cache[name] = read();
        sources[name] = 'ok';
    } catch (err) {
        sources[name] = cache[name] ? 'kept' : 'none';
        console.error(name + ': ' + String(err.message || err).split('\n')[0]);
    }
    return cache[name];
}

const gh = (...a) => JSON.parse(run('gh', a));
const repoInfo = fromSource('repo', () => gh('repo', 'view', '--json', 'owner,name,url')) || {};
const owner = (repoInfo.owner && repoInfo.owner.login) || '';
const isOwner = (login) => !!login && login.toLowerCase() === owner.toLowerCase();
const issues = fromSource('issues', () => gh('issue', 'list', '--state', 'all', '--limit', '500', '--json',
    'number,title,author,labels,state,stateReason,createdAt,updatedAt,closedAt,url,body,comments')) || [];
const pulls = fromSource('pulls', () => gh('pr', 'list', '--state', 'all', '--limit', '300', '--json',
    'number,title,author,state,createdAt,updatedAt,mergedAt,closedAt,url,headRefName,mergeCommit,body')) || [];

async function readCurseForge() {
    const threads = [];
    for (let page = 0; page < 40; page++) {
        const res = await fetch('https://www.curseforge.com/api/v1/mods/' + CF_PROJECT + '/comments?page=' + page,
            { headers: { 'User-Agent': 'Mozilla/5.0' } });
        if (!res.ok) { throw new Error('CurseForge answered ' + res.status); }
        const json = await res.json();
        threads.push(...(json.data || []));
        const p = json.pagination || {};
        if (!json.data || !json.data.length || (page + 1) * (p.pageSize || 20) >= (p.totalCount || 0)) { break; }
    }
    return threads;
}
let cfThreads = cache.curseforge || [];
try {
    cfThreads = await readCurseForge();
    cache.curseforge = cfThreads;
    sources.curseforge = 'ok';
} catch (err) {
    sources.curseforge = cache.curseforge ? 'kept' : 'none';
    console.error('curseforge: ' + String(err.message || err).split('\n')[0]);
}
fs.writeFileSync(cachePath, JSON.stringify(cache));

// The board -----------------------------------------------------------------------------------

const versionOrder = new Map(releases.map((r, i) => [r.version, i]));

// Where a request stands, from the commits made for it.
function standing(shas) {
    const made = shas.map((s) => commits.get(s)).filter(Boolean);
    const merged = made.filter((c) => c.release !== WIP);
    if (!made.length) { return null; }
    if (!merged.length) { return { status: 'progress' }; }
    if (merged.some((c) => c.release === UNRELEASED)) { return { status: 'ready' }; }
    const last = merged.reduce((a, b) => (versionOrder.get(a.release) >= versionOrder.get(b.release) ? a : b));
    return { status: 'shipped', version: last.release };
}

function sortShas(shas) {
    return [...new Set(shas)].sort((a, b) => (commits.get(a).date < commits.get(b).date ? -1 : 1));
}

// A release note that names an issue, like "(#23)".
function notesFor(number) {
    const found = [];
    for (const [version, release] of notes) {
        for (const section of release.sections) {
            for (const entry of section.entries) {
                if (new RegExp('#' + number + '\\b').test(entry.text)) {
                    found.push({ version, heading: section.heading, name: entry.name, text: entry.text });
                }
            }
        }
    }
    return found;
}

const refsTo = new Map(); // issue number -> shas whose message names it
for (const c of commits.values()) {
    for (const n of c.refs) {
        if (!refsTo.has(n)) { refsTo.set(n, []); }
        refsTo.get(n).push(c.sha);
    }
}

const items = [];
const pullNumbers = new Set(pulls.map((p) => p.number));

for (const issue of issues) {
    const mine = (issue.comments || []).filter((c) => isOwner(c.author && c.author.login));
    const shas = [...(refsTo.get(issue.number) || [])];
    for (const comment of mine) {
        for (const m of comment.body.matchAll(/\b[0-9a-f]{7,40}\b/g)) {
            if (/[a-f]/.test(m[0])) {
                const sha = findCommit(m[0]);
                if (sha) { shas.push(sha); }
            }
        }
    }
    const handed = dispatched['gh:issue:' + issue.number];
    if (handed && handed.branch) {
        for (const c of wip.commits) { if (c.branch === handed.branch) { shas.push(c.sha); } }
    }
    const linked = sortShas(shas);
    const noted = notesFor(issue.number);
    const labels = (issue.labels || []).map((l) => l.name);
    let where = standing(linked);
    if (!where && noted.length) {
        where = noted[0].version === UNRELEASED ? { status: 'ready' } : { status: 'shipped', version: noted[0].version };
    }
    if (!where) {
        if (issue.state === 'OPEN') { where = { status: 'open' }; }
        else if (issue.stateReason === 'COMPLETED') {
            // No commit names it: take the last version a reply of ours says it's in.
            const said = mine.flatMap((c) => [...c.body.matchAll(/\b\d+\.\d+\.\d+(?:-[\w.]+)?\b/g)].map((m) => m[0]))
                .filter((v) => versionOrder.has(v));
            where = { status: 'shipped', version: said[said.length - 1] };
        } else { where = { status: 'declined' }; }
    }
    const reply = mine[mine.length - 1];
    items.push({
        id: 'gh-' + issue.number, source: 'github', number: issue.number,
        kind: labels.includes('bug') ? 'bug' : labels.includes('enhancement') ? 'request' : 'issue',
        title: issue.title, author: issue.author ? issue.author.login : '', url: issue.url,
        opened: issue.createdAt, updated: issue.updatedAt, closed: issue.closedAt || null,
        state: issue.state === 'OPEN' ? 'open' : 'closed', ...where,
        branch: handed && handed.branch || null,
        body: clip(issue.body), comments: (issue.comments || []).length,
        reply: reply ? { date: reply.createdAt, text: clip(reply.body) } : null,
        commits: linked, notes: noted,
    });
}

for (const pull of pulls) {
    const author = pull.author || {};
    if (author.is_bot || /^app\//.test(author.login || '')) { continue; }
    const shas = [...(refsTo.get(pull.number) || [])];
    const mergedAs = pull.mergeCommit && findCommit(pull.mergeCommit.oid);
    if (mergedAs) { shas.push(mergedAs); }
    const linked = sortShas(shas);
    let where = standing(linked);
    if (!where) {
        where = pull.state === 'OPEN' ? { status: 'progress' }
            : pull.state === 'MERGED' ? { status: 'shipped' } : { status: 'declined' };
    }
    items.push({
        id: 'gh-' + pull.number, source: 'github', number: pull.number, kind: 'pull',
        title: pull.title, author: author.login || '', url: pull.url,
        opened: pull.createdAt, updated: pull.updatedAt, closed: pull.mergedAt || pull.closedAt || null,
        state: pull.state === 'OPEN' ? 'open' : 'closed', ...where,
        branch: pull.headRefName || null, body: clip(pull.body), comments: 0, reply: null,
        commits: linked, notes: notesFor(pull.number).filter(() => !issues.some((i) => i.number === pull.number)),
    });
}

// CurseForge: a thread with its replies flattened, and whether the last word is the project's.
function flatten(thread) {
    const all = [];
    const walk = (list) => { for (const r of list || []) { all.push(r); walk(r.replies); } };
    walk(thread.replies);
    return all.sort((a, b) => a.datePosted - b.datePosted);
}
const iso = (ms) => new Date(ms).toISOString();
const threadsById = new Map(cfThreads.map((t) => [String(t.id), t]));
const cfItemOf = new Map(); // thread id -> the first board item made from it

for (const [key, d] of Object.entries(dispatched)) {
    const m = /^cf:(\d+)(?:#(.+))?$/.exec(key);
    if (!m) { continue; }
    const thread = threadsById.get(m[1]);
    const replies = thread ? flatten(thread) : [];
    const mine = replies.filter((r) => isOwner(r.author && r.author.username));
    const usable = /ready|merged|pushed|released|shipped/i.test(d.status || '');
    const shas = [];
    const sha = usable && findCommit(d.commit);
    if (sha) { shas.push(sha); }
    if (d.branch) {
        for (const c of wip.commits) { if (c.branch === d.branch) { shas.push(c.sha); } }
    }
    const linked = sortShas(shas);
    const where = standing(linked) || { status: 'open' };
    const id = 'cf-' + m[1] + (m[2] ? '-' + m[2].replace(/[^A-Za-z0-9]+/g, '-') : '');
    if (!cfItemOf.has(m[1])) { cfItemOf.set(m[1], id); }
    items.push({
        id, source: 'curseforge', number: null,
        kind: /^fix\//.test(d.branch || '') ? 'bug' : 'request',
        title: d.title || (thread ? clip(thread.text, 80) : key), author: d.author || '', url: CF_URL,
        opened: thread ? iso(thread.datePosted) : d.startedAt || null,
        updated: replies.length ? iso(replies[replies.length - 1].datePosted) : thread ? iso(thread.datePosted) : null,
        closed: null, state: where.status === 'shipped' ? 'closed' : 'open', ...where,
        branch: d.branch || null,
        note: where.status === 'open' && d.status ? d.status : null,
        body: thread ? clip(thread.text) : '', comments: replies.length,
        reply: mine.length ? { date: iso(mine[mine.length - 1].datePosted), text: clip(mine[mine.length - 1].text) } : null,
        commits: linked, notes: [],
    });
}

const comments = cfThreads.map((t) => {
    const replies = flatten(t);
    const mine = replies.filter((r) => isOwner(r.author && r.author.username));
    const last = replies[replies.length - 1];
    return {
        id: String(t.id), author: t.author ? t.author.displayName || t.author.username : '',
        date: iso(t.datePosted), text: clip(t.text), replies: replies.length,
        // The feed doesn't list every reply of a thread, so this is "none seen", not "none".
        waiting: !isOwner(t.author && t.author.username) && !mine.length,
        last: last ? iso(last.datePosted) : iso(t.datePosted),
        reply: mine.length ? clip(mine[mine.length - 1].text, 800) : null,
        item: cfItemOf.get(String(t.id)) || null,
    };
}).sort((a, b) => (a.last < b.last ? 1 : -1));

// Output --------------------------------------------------------------------------------------

let manifest = {};
try { manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8')); } catch { /* first run */ }
const next = {};

// Writes a file only when what it says changed; `stamp` is added without counting as a change.
function emit(name, body, stamp) {
    const rel = 'data/' + name;
    const hash = crypto.createHash('sha1').update(body).digest('hex');
    const file = path.join(out, rel);
    next[rel] = hash;
    if (manifest[rel] !== hash || !fs.existsSync(file)) {
        fs.writeFileSync(file, stamp ? stamp(body) : body);
    }
}
const rows = (list) => '[\n' + list.map((r) => JSON.stringify(r)).join(',\n') + '\n]';

const allCommits = [...releases].reverse().flatMap((r) => r.commits).concat(wip.commits);
emit('commits.json', rows(allCommits.map((c) => ({
    sha: c.sha, date: c.date, type: c.type, scope: c.scope, summary: c.summary, release: c.release,
    branch: c.branch || undefined, by: c.author !== ownName ? c.author : undefined,
    local: unpushed.has(c.sha) || undefined, refs: c.refs.length ? c.refs : undefined,
    adds: c.adds, dels: c.dels, files: c.files.length,
}))));

emit('releases.json', rows([...releases].reverse().map((r) => {
    const files = new Map();
    for (const c of r.commits) {
        for (const f of c.files) {
            const t = files.get(f.path) || [f.path, 0, 0, 0];
            t[1] += f.adds; t[2] += f.dels; t[3] += 1;
            files.set(f.path, t);
        }
    }
    const note = notes.get(r.version) || { date: null, sections: [] };
    const last = r.commits[0];
    return {
        version: r.version, tag: r.tag, prev: r.prev,
        date: note.date || (r.tag && last ? last.date.slice(0, 10) : null),
        commits: r.commits.length, adds: r.commits.reduce((n, c) => n + c.adds, 0),
        dels: r.commits.reduce((n, c) => n + c.dels, 0),
        sections: note.sections, files: [...files.values()].sort((a, b) => b[1] + b[2] - a[1] - a[2]),
    };
})));

emit('comments.json', rows(comments));

for (const r of [...releases, wip]) {
    const name = 'patch-' + (r.version === UNRELEASED ? 'unreleased' : r.version === WIP ? 'wip' : r.version) + '.json';
    const rel = 'data/' + name;
    if (r.tag && !FORCE && manifest[rel] && fs.existsSync(path.join(out, rel))) {
        next[rel] = manifest[rel];
        continue;
    }
    if (r === wip) { r.range = null; }
    let body;
    if (r === wip) {
        // Each branch has its own range; read them one at a time.
        const merged = { version: WIP, commits: {} };
        for (const b of new Set(wip.commits.map((c) => c.branch))) {
            const part = patchFile({ version: WIP, range: BRANCH + '..' + b, commits: wip.commits.filter((c) => c.branch === b) });
            Object.assign(merged.commits, part.commits);
        }
        body = JSON.stringify(merged);
    } else {
        body = JSON.stringify(patchFile(r));
    }
    emit(name, body);
}

const latest = releases[releases.length - 2];
const board = {
    repo: { url: repoInfo.url || '', name: repoInfo.name || 'ForeverPlusPlus' },
    head: { sha: head, date: commits.get(head) ? commits.get(head).date : null },
    latest: latest ? latest.version : null,
    unreleased: releases[releases.length - 1].commits.length,
    unpushed: unpushed.size,
    curseforge: CF_URL,
    sources,
    items: items.sort((a, b) => ((a.updated || '') < (b.updated || '') ? 1 : -1)),
    branches,
};
const generated = new Date().toISOString();
emit('board.json', JSON.stringify(board), (body) => '{"generated":' + JSON.stringify(generated) + ',' + body.slice(1));

fs.writeFileSync(manifestPath, JSON.stringify(next, null, 1));
let published = {};
try { published = JSON.parse(fs.readFileSync(publishedPath, 'utf8')); } catch { /* never published */ }
const changed = Object.keys(next).filter((rel) => published[rel] !== next[rel]);
console.log(changed.length ? 'CHANGED ' + changed.join(' ') : 'CHANGED (none)');
