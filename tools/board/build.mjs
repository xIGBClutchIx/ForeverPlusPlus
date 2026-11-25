#!/usr/bin/env node
// Builds the data files behind the Forever++ Board artifact (tools/board/index.html): each piece
// of work (an issue, a pull request, or a request from a CurseForge comment) with where it stands
// and the commits made for it, every commit with the release it shipped in, the release notes,
// the conversations the work came from, and the diffs. Reads git, CHANGELOG.md, the TOC,
// GitHub (the gh CLI), CurseForge's public comment feed, and, when it's there, the inbox task's
// state file.
//
//   node tools/board/build.mjs [--out <dir>] [--state <file>] [--branch main] [--force]
//   node tools/board/build.mjs --published
//
// Writes <out>/data/*.json (out/ by default, which git ignores):
//   board.json            the work items, the local branches, and what the next release holds
//   commits.json          every commit read, newest release first
//   releases.json         each release's notes, numbers, and the files its commits touched
//   comments.json         the conversations: CurseForge threads and GitHub issues, with replies
//   diff-<version>.json   a release's combined diff, file by file (diff-unreleased: since the last tag)
//   patch-<version>.json  a release's diffs commit by commit (patch-unreleased: not tagged yet)
//   work-<item>.json      one item's combined diff and its commits' own diffs
// Then it prints, after CHANGED, the files that differ from what was last published, so only
// those need publishing with index.html, and after REMOVED the ones the artifact holds that are
// gone (publish those as null). Run it with --published once a publish went through, to record
// that. A released version's diff files never change, so they're written once (--force writes
// them all again). Same inputs give the same bytes, apart from board.json's time stamp.
//
// An item's commits are found by itself: those whose message names its issue, those a reply of
// ours links, a pull request's merge, and for an inbox entry the branch it was handed: a branch
// merged into main brings the commits of its merge ("Merge branch 'x'"), and those of a branch it
// was built on; one not merged yet brings what it has over main. The entry's commit and commits
// count too. Needs Node 20 or newer, git, and gh signed in; with GitHub or CurseForge unreachable
// it keeps what the last run read from them.
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
const EMPTY_TREE = '4b825dc642cb6eb9a060e54bf8d69288fbee4904';
const MAX_PATCH = 80000; // bytes of one file's diff kept; a longer one is cut at a line
const MAX_TEXT = 2400; // letters of a request's or reply's text kept
const MAX_GENERATED = 400; // changed lines up to which a generated file's diff is kept
const MAX_BRANCH = 60; // commits over main up to which a branch handed to a request is read
// Generated data: counted in a commit's numbers, and its diff is kept only when it's small.
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
const EXCLUDE = GENERATED.map((g) => ':(exclude)' + g);
const revList = (range) => lines(git('rev-list', '--no-merges', range));

// Git: releases and commits -------------------------------------------------------------------

const tags = lines(git('tag', '-l', 'v*'))
    .map((tag) => ({ tag, depth: Number(git('rev-list', '--count', tag).trim()) }))
    .sort((a, b) => a.depth - b.depth);

// "dir/{old => new}/file" and "old => new", as numstat writes a rename, to the new path.
function newPath(p) {
    return p.replace(/\{(.*?) => (.*?)\}/g, '$2').replace(/^.* => /, '').replace(/\/\//g, '/');
}
function numstat(text) {
    const files = [];
    for (const line of text.split('\n')) {
        const m = /^(\d+|-)\t(\d+|-)\t(.+)$/.exec(line);
        if (m) { files.push({ path: newPath(m[3]), adds: Number(m[1]) || 0, dels: Number(m[2]) || 0, binary: m[1] === '-' }); }
    }
    return files;
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
        const files = numstat(tail);
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
const unreleased = { version: UNRELEASED, tag: null, range: unreleasedRange, prev, commits: readCommits(unreleasedRange, UNRELEASED) };
releases.push(unreleased);

// The author with the most commits is the project's own: only others' names are kept, as credit.
const byAuthor = new Map();
for (const c of commits.values()) { byAuthor.set(c.author, (byAuthor.get(c.author) || 0) + 1); }
const ownName = [...byAuthor].sort((a, b) => b[1] - a[1])[0]?.[0];

let unpushed = new Set();
let hasRemote = true;
try { unpushed = new Set(lines(git('rev-list', 'origin/' + BRANCH + '..' + BRANCH))); } catch { hasRemote = false; }

// The inbox task's state: which request each branch and commit is for.
let inbox = { dispatched: {} };
try { inbox = JSON.parse(fs.readFileSync(statePath, 'utf8')); } catch { /* not on this machine */ }
const dispatched = inbox.dispatched || {};

// Merges into main, newest first, by the branch or pull request each brought in.
const mergesOf = new Map(); // branch -> [{ sha, p1, p2 }]
const mergeOfPull = new Map(); // pull number -> merge
const mergeBySha = new Map();
for (const line of lines(git('log', '--merges', '--first-parent', '--format=%H%x02%P%x02%s', BRANCH))) {
    const [sha, parents, subject] = line.split('\x02');
    const [p1, p2] = parents.split(' ');
    const merge = { sha, p1, p2 };
    mergeBySha.set(sha, merge);
    const named = /^Merge branch '([^']+)'/.exec(subject) || /^merge: .*\(([^()\s]+)\)\s*$/.exec(subject);
    if (named) {
        if (!mergesOf.has(named[1])) { mergesOf.set(named[1], []); }
        mergesOf.get(named[1]).push(merge);
    }
    const pull = /^Merge pull request #(\d+)/.exec(subject);
    if (pull) { mergeOfPull.set(Number(pull[1]), merge); }
}
const mergeRange = (m) => revList(m.p1 + '..' + m.p2);

// Local branches. Those not merged yet are listed; a request's is read when it's not too long.
const tips = new Map(); // branch -> sha
const branches = [];
const wanted = new Set(Object.values(dispatched).map((d) => d.branch).filter(Boolean));
const wip = { version: WIP, commits: [] };
for (const line of lines(git('for-each-ref', '--format=%(refname:short)%09%(objectname)%09%(committerdate:iso-strict)%09%(subject)', 'refs/heads'))) {
    const [name, sha, date, subject] = line.split('\t');
    if (name === BRANCH) { continue; }
    tips.set(name, sha);
    const ahead = Number(git('rev-list', '--count', BRANCH + '..' + name).trim());
    if (!ahead) { continue; }
    branches.push({ name, ahead, date, subject });
    if (wanted.has(name) && ahead <= MAX_BRANCH) {
        wip.commits.push(...readCommits(BRANCH + '..' + name, WIP, name));
    }
}
branches.sort((a, b) => (a.date < b.date ? 1 : a.date > b.date ? -1 : a.name < b.name ? -1 : 1));

function findCommit(prefix) {
    if (!prefix || prefix.length < 7) { return null; }
    if (commits.has(prefix)) { return prefix; }
    for (const sha of commits.keys()) { if (sha.startsWith(prefix)) { return sha; } }
    return null;
}

// The commits a branch brought: its merges into main, and a branch it was built on and that was
// merged on its own first; or, not merged yet, what it has over main. `via` names every branch
// the work was on, the asked-for one first.
function branchWork(branch) {
    const shas = [];
    const via = [branch];
    const merges = mergesOf.get(branch) || [];
    if (merges.length) {
        for (const m of merges) { shas.push(...mergeRange(m)); }
        const history = new Set(lines(git('rev-list', merges[0].p2)));
        for (const [name, list] of mergesOf) {
            if (name === branch) { continue; }
            for (const m of list) {
                if (history.has(m.p2) && !history.has(m.sha)) {
                    shas.push(...mergeRange(m));
                    if (!via.includes(name)) { via.push(name); }
                }
            }
        }
    } else {
        for (const c of wip.commits) { if (c.branch === branch) { shas.push(c.sha); } }
    }
    // A local branch whose tip is inside the work was a step of it, like a first part.
    const inside = new Set(shas);
    for (const [name, sha] of tips) {
        if (inside.has(sha) && !via.includes(name)) { via.push(name); }
    }
    return { shas: shas.filter((s) => commits.has(s)), via };
}

// Diffs ---------------------------------------------------------------------------------------

// The files of a diff's text, as git writes it: path -> { status, from, patch, cut }.
function fileDiffs(text) {
    const files = new Map();
    for (const part of text.split(/^diff --git /m).slice(1)) {
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
    return files;
}

// One file's entry in a data file: its numbers, and its diff when it's kept.
function entry(f, d) {
    const generated = isGenerated(f.path);
    const e = { path: f.path, adds: f.adds, dels: f.dels, status: d ? d.status : 'changed' };
    if (generated) { e.generated = true; }
    if (d && d.from) { e.from = d.from; }
    if (d && d.patch) { e.patch = d.patch; if (d.cut) { e.cut = true; } }
    else if (generated) { e.note = 'generated'; }
    else if (f.binary) { e.note = 'binary'; }
    else { e.note = 'moved'; }
    return e;
}

// Each commit's own diff, for the commits given.
function commitDiffs(list, range) {
    const bySha = new Map();
    if (list.length) {
        const text = range
            ? git('log', '-p', '--no-merges', '-M', '--no-color', '--no-ext-diff', '--format=%x01%H', range, '--', '.', ...EXCLUDE)
            : git('show', '-M', '--no-color', '--no-ext-diff', '--format=%x01%H', ...list.map((c) => c.sha), '--', '.', ...EXCLUDE);
        for (const chunk of text.split('\x01').slice(1)) {
            bySha.set(chunk.slice(0, chunk.indexOf('\n')).trim(), fileDiffs(chunk));
        }
    }
    const result = {};
    for (const c of list) {
        const diffs = bySha.get(c.sha) || new Map();
        result[c.sha] = c.files.map((f) => {
            if (!isGenerated(f.path)) { return entry(f, diffs.get(f.path)); }
            // A generated file's diff is kept when the change is small enough to read.
            const small = !f.binary && f.adds + f.dels <= MAX_GENERATED;
            const text = small ? git('show', '-M', '--no-color', '--no-ext-diff', '--format=', c.sha, '--', f.path) : '';
            return entry(f, small ? fileDiffs(text).get(f.path) : null);
        });
    }
    return result;
}

// The net change from one tree to another, file by file, in path order; only `paths` when given.
function netDiff(from, to, paths) {
    if (paths && !paths.length) { return []; }
    const spec = paths || ['.'];
    const stats = numstat(git('diff', '--numstat', '-M', from, to, '--', ...spec));
    const diffs = fileDiffs(git('diff', '-M', '--no-color', '--no-ext-diff', from, to, '--', ...spec, ...EXCLUDE));
    return stats.map((f) => {
        if (!isGenerated(f.path)) { return entry(f, diffs.get(f.path)); }
        const small = !f.binary && f.adds + f.dels <= MAX_GENERATED;
        return entry(f, small ? fileDiffs(git('diff', '-M', '--no-color', '--no-ext-diff', from, to, '--', f.path)).get(f.path) : null);
    }).sort((a, b) => (a.path < b.path ? -1 : 1));
}

// Several commits' changes together. When they're one line of history, like a branch, it's the
// diff from before the first to the last, for every file no other commit in between touched;
// a file another commit touched in between, or commits that aren't one line, shows each of
// their own diffs to it in order instead (`pieces`), so nothing of others' is shown as theirs.
function combinedDiff(list, own) {
    const shas = list.map((c) => c.sha);
    const S = new Set(shas);
    let tip = null, order = null;
    for (const cand of [...list].reverse().slice(0, 4)) {
        const ancestry = lines(git('rev-list', '--topo-order', cand.sha));
        const seen = new Set(ancestry);
        if (shas.every((s) => seen.has(s))) { tip = cand.sha; order = ancestry; break; }
    }
    let base = null, others = new Set();
    if (tip) {
        const first = order.filter((s) => S.has(s)).pop();
        try { base = git('rev-parse', first + '^').trim(); } catch { base = EMPTY_TREE; }
        const range = new Set(base === EMPTY_TREE ? revList(tip) : revList(base + '..' + tip));
        if (shas.every((s) => range.has(s))) {
            others = new Set([...range].filter((s) => !S.has(s)));
        } else { base = null; }
    }
    const touched = new Set(); // files a commit outside these touched in between
    if (base && others.size) {
        const text = git('log', '--no-merges', '-M', '--name-only', '--format=%x01%H', base === EMPTY_TREE ? tip : base + '..' + tip);
        for (const chunk of text.split('\x01').slice(1)) {
            const [sha, ...files] = lines(chunk);
            if (others.has(sha)) { for (const f of files) { touched.add(f); } }
        }
    }
    const paths = [...new Set(list.flatMap((c) => c.files.map((f) => f.path)))];
    const whole = base ? paths.filter((p) => !touched.has(p)) : [];
    const files = base ? netDiff(base, tip, others.size ? whole : null) : [];
    const done = new Set(files.map((f) => f.path));
    for (const f of files) { if (f.from) { done.add(f.from); } }
    for (const p of paths) {
        if (done.has(p)) { continue; }
        const pieces = [];
        for (const c of list) {
            const e = (own[c.sha] || []).find((x) => x.path === p);
            if (e) { pieces.push({ sha: c.sha, ...e, path: undefined }); }
        }
        if (!pieces.length) { continue; }
        files.push({
            path: p, adds: pieces.reduce((n, x) => n + x.adds, 0), dels: pieces.reduce((n, x) => n + x.dels, 0),
            status: pieces.length === 1 ? pieces[0].status : 'changed', generated: isGenerated(p) || undefined,
            pieces: pieces.map(({ path: _, ...x }) => x),
        });
    }
    files.sort((a, b) => (a.path < b.path ? -1 : 1));
    return {
        from: base, to: tip, exact: !!base && !touched.size,
        adds: files.reduce((n, f) => n + f.adds, 0), dels: files.reduce((n, f) => n + f.dels, 0), files,
    };
}

// Release notes, the TOC, and the in-game changelog ------------------------------------------

const notes = new Map(); // version -> { date, sections: [{ heading, entries: [{ name, text }] }] }
{
    let current = null;
    let section = null;
    for (const line of fs.readFileSync(path.join(repo, 'CHANGELOG.md'), 'utf8').split(/\r?\n/)) {
        const release = /^## (\S+)(?: \((\d{4}-\d{2}-\d{2})\))?/.exec(line);
        const heading = /^### (.+)$/.exec(line);
        const item = /^- (.+)$/.exec(line);
        if (release) {
            current = { date: release[2] || null, sections: [] };
            section = null;
            notes.set(release[1], current);
        } else if (heading && current) {
            section = { heading: heading[1].trim(), entries: [] };
            current.sections.push(section);
        } else if (item && section) {
            const named = /^((?:\*\*[^*]+\*\*(?:, | and |, and )?)+): (.+)$/.exec(item[1]);
            section.entries.push(named
                ? { name: named[1].replace(/\*\*/g, ''), text: named[2] }
                : { name: '', text: item[1] });
        }
    }
}
const readText = (p) => { try { return fs.readFileSync(path.join(repo, p), 'utf8'); } catch { return ''; } };
const tocVersion = (/^## Version:\s*(\S+)/m.exec(readText('ForeverPlusPlus/ForeverPlusPlus.toc')) || [])[1] || null;
const gameNotes = /^\s*version = L\.CHANGELOG_UNRELEASED,/m.test(readText('ForeverPlusPlus/Changelog.lua'));

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

// A CurseForge comment's HTML as plain text, its links as [text](url) for the page to link.
function htmlText(html) {
    const decode = (s) => s.replace(/&nbsp;/g, ' ').replace(/&lt;/g, '<').replace(/&gt;/g, '>')
        .replace(/&quot;/g, '"').replace(/&#39;|&#x27;|&apos;/g, "'")
        .replace(/&#(\d+);/g, (_, n) => String.fromCodePoint(Number(n)))
        .replace(/&#x([0-9a-f]+);/gi, (_, n) => String.fromCodePoint(parseInt(n, 16))).replace(/&amp;/g, '&');
    return decode(String(html || '')
        .replace(/<a\b[^>]*?href="([^"]*)"[^>]*>([\s\S]*?)<\/a>/gi, (_, href, t) => {
            const text = t.replace(/<[^>]+>/g, '');
            const url = decode(href);
            return /^https:\/\//.test(url) && decode(text) !== url ? '[' + text + '](' + url + ')' : text;
        })
        .replace(/<br\s*\/?>/gi, '\n').replace(/<li[^>]*>/gi, '- ').replace(/<\/(p|div|li|h\d|blockquote|pre)>/gi, '\n')
        .replace(/<[^>]+>/g, ''))
        .replace(/ /g, ' ').replace(/[ \t]+\n/g, '\n').replace(/\n{3,}/g, '\n\n').trim();
}

// The board -----------------------------------------------------------------------------------

const versionOrder = new Map(releases.map((r, i) => [r.version, i]));
const iso = (ms) => new Date(ms).toISOString();
const latestOf = (...dates) => dates.filter(Boolean).sort().pop() || null;

// Conversations: a CurseForge thread or a GitHub issue, every post in order. `mine` marks ours.
const conversations = [];
for (const t of cfThreads) {
    const posts = [];
    const walk = (list) => { for (const r of list || []) { posts.push(r); walk(r.replies); } };
    walk(t.replies);
    posts.sort((a, b) => a.datePosted - b.datePosted);
    const user = t.author ? t.author.username : '';
    conversations.push({
        id: 'cf-' + t.id, source: 'curseforge', url: CF_URL, title: null,
        author: t.author ? t.author.displayName || user : '', user, mine: isOwner(user) || undefined,
        date: iso(t.datePosted), text: clip(htmlText(t.body) || t.text),
        posts: posts.map((r) => ({
            user: r.author ? r.author.username : '', name: r.author ? r.author.displayName || r.author.username : '',
            mine: isOwner(r.author && r.author.username) || undefined, date: iso(r.datePosted), text: clip(htmlText(r.body) || r.text),
        })),
        items: [],
    });
}
for (const issue of issues) {
    const user = issue.author ? issue.author.login : '';
    conversations.push({
        id: 'gh-' + issue.number, source: 'github', url: issue.url, title: issue.title, number: issue.number,
        author: user, user, mine: isOwner(user) || undefined, state: issue.state === 'OPEN' ? 'open' : 'closed',
        date: issue.createdAt, text: clip(issue.body),
        posts: (issue.comments || []).map((c) => ({
            user: c.author ? c.author.login : '', name: c.author ? c.author.login : '',
            mine: isOwner(c.author && c.author.login) || undefined, date: c.createdAt, text: clip(c.body), url: c.url || undefined,
        })),
        items: [],
    });
}
for (const c of conversations) {
    c.last = latestOf(c.date, ...c.posts.map((p) => p.date));
    // The state file's `replied` ("cf:<id>" or "gh:issue:<n>" -> a date) records a reply the feeds
    // can't show: CurseForge's lists only a thread's first reply.
    const key = c.source === 'github' ? 'gh:issue:' + c.number : 'cf:' + c.id.slice(3);
    c.replied = c.posts.some((p) => p.mine) || Boolean((inbox.replied || {})[key]) || undefined;
}
const conversationById = new Map(conversations.map((c) => [c.id, c]));

// Where work stands, from the commits made for it.
function standing(shas) {
    const made = shas.map((s) => commits.get(s)).filter(Boolean);
    const merged = made.filter((c) => c.release !== WIP);
    if (!made.length) { return null; }
    if (!merged.length) { return { status: 'progress' }; }
    if (merged.some((c) => c.release === UNRELEASED)) {
        return { status: 'ready', pushed: hasRemote && !merged.some((c) => unpushed.has(c.sha)) };
    }
    const last = merged.reduce((a, b) => (versionOrder.get(a.release) >= versionOrder.get(b.release) ? a : b));
    return { status: 'shipped', version: last.release };
}

function sortShas(shas) {
    return [...new Set(shas)].filter((s) => commits.has(s))
        .sort((a, b) => (commits.get(a).date < commits.get(b).date ? -1 : commits.get(a).date > commits.get(b).date ? 1 : a < b ? -1 : 1));
}

// A release note that names an issue, like "(#23)".
function notesFor(number) {
    const found = [];
    for (const [version, release] of notes) {
        for (const section of release.sections) {
            for (const e of section.entries) {
                if (new RegExp('#' + number + '\\b').test(e.text)) {
                    found.push({ version, heading: section.heading, name: e.name, text: e.text });
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

// What the inbox task recorded for an entry: its branch's work, and the commits it listed.
function handedWork(d) {
    const shas = [];
    let via = [];
    if (d.branch) {
        const w = branchWork(d.branch);
        shas.push(...w.shas);
        via = w.via;
    }
    for (const prefix of [d.commit, ...(Array.isArray(d.commits) ? d.commits : [])]) {
        const found = findCommit(prefix);
        if (found) { shas.push(found); }
    }
    return { shas, via };
}

const items = [];
const handedIssue = new Map(); // issue number -> inbox entry without a #slug
const extraEntries = []; // [key, source, thread id, slug, entry]
for (const [key, d] of Object.entries(dispatched)) {
    const m = /^(cf|gh:issue):(\d+)(?:#(.+))?$/.exec(key);
    if (!m) { continue; }
    if (m[1] === 'gh:issue' && !m[3]) { handedIssue.set(Number(m[2]), d); continue; }
    extraEntries.push([key, m[1] === 'cf' ? 'curseforge' : 'github', (m[1] === 'cf' ? 'cf-' : 'gh-') + m[2], m[3] || null, d]);
}

for (const issue of issues) {
    const convo = conversationById.get('gh-' + issue.number);
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
    const handed = handedIssue.get(issue.number);
    let via = [];
    if (handed) {
        const w = handedWork(handed);
        shas.push(...w.shas);
        via = w.via;
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
    items.push({
        id: 'gh-' + issue.number, source: 'github', number: issue.number,
        kind: labels.includes('bug') ? 'bug' : labels.includes('enhancement') ? 'request' : 'issue',
        title: issue.title, author: issue.author ? issue.author.login : '', url: issue.url,
        opened: issue.createdAt, updated: issue.updatedAt, closed: issue.closedAt || null,
        state: issue.state === 'OPEN' ? 'open' : 'closed', ...where,
        branch: handed && handed.branch || null, branches: via.length > 1 ? via : undefined,
        note: where.status === 'open' && handed && handed.status ? handed.status : null,
        thread: convo ? convo.id : null, commits: linked, notes: noted,
    });
}

for (const pull of pulls) {
    const author = pull.author || {};
    if (author.is_bot || /^app\//.test(author.login || '')) { continue; }
    const shas = [...(refsTo.get(pull.number) || [])];
    const oid = pull.mergeCommit && pull.mergeCommit.oid;
    const merge = (oid && mergeBySha.get(oid)) || mergeOfPull.get(pull.number);
    if (merge) { shas.push(...mergeRange(merge)); }
    else if (oid && findCommit(oid)) { shas.push(findCommit(oid)); }
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
        branch: pull.headRefName || null, body: clip(pull.body),
        thread: null, commits: linked, notes: notesFor(pull.number).filter(() => !issues.some((i) => i.number === pull.number)),
    });
}

// Inbox entries: a request from a CurseForge thread, or a second piece of work from a thread or
// issue (a "#slug" key), each an item of its own that points at the conversation it came from.
for (const [key, source, threadId, slugKey, d] of extraEntries) {
    const convo = conversationById.get(threadId);
    const { shas, via } = handedWork(d);
    const linked = sortShas(shas);
    const where = standing(linked) || { status: 'open' };
    const lastCommit = linked.length ? commits.get(linked[linked.length - 1]).date : null;
    items.push({
        id: threadId + (slugKey ? '-' + slugKey.replace(/[^A-Za-z0-9]+/g, '-') : ''), source,
        number: source === 'github' ? Number(threadId.slice(3)) : null,
        kind: /^fix\//.test(d.branch || '') ? 'bug' : 'request',
        title: d.title || (convo ? clip(convo.text, 80) : key), author: d.author || (convo ? convo.user : ''),
        url: convo ? convo.url : CF_URL,
        opened: convo ? convo.date : d.startedAt || null,
        updated: latestOf(convo && convo.last, lastCommit, d.startedAt),
        closed: null, state: where.status === 'shipped' ? 'closed' : 'open', ...where,
        branch: d.branch || null, branches: via.length > 1 ? via : undefined,
        note: where.status === 'open' && d.status ? d.status : null,
        thread: convo ? convo.id : null, commits: linked, notes: [],
    });
}

const order = { open: 0, progress: 1, ready: 2, shipped: 3, declined: 4 };
items.sort((a, b) => ((a.updated || '') < (b.updated || '') ? 1 : (a.updated || '') > (b.updated || '') ? -1 : a.id < b.id ? -1 : 1));
for (const item of items) {
    const convo = item.thread && conversationById.get(item.thread);
    if (convo) { convo.items.push(item.id); }
}
for (const c of conversations) {
    c.items.sort((a, b) => {
        const x = items.find((i) => i.id === a), y = items.find((i) => i.id === b);
        return order[x.status] - order[y.status] || (a < b ? -1 : 1);
    });
}
conversations.sort((a, b) => (a.last < b.last ? 1 : a.last > b.last ? -1 : a.id < b.id ? -1 : 1));

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
// A file written once: kept as it is when the manifest has it, unless --force.
function keep(name) {
    const rel = 'data/' + name;
    if (FORCE || !manifest[rel] || !fs.existsSync(path.join(out, rel))) { return false; }
    next[rel] = manifest[rel];
    return true;
}
const rows = (list) => '[\n' + list.map((r) => JSON.stringify(r)).join(',\n') + '\n]';
const fileName = (version) => (version === UNRELEASED ? 'unreleased' : version);

// Each release's diffs: commit by commit, and all of it together.
const netOf = new Map(); // version -> { files, adds, dels }
for (const r of releases) {
    const patch = 'patch-' + fileName(r.version) + '.json';
    if (!(r.tag && keep(patch))) {
        emit(patch, JSON.stringify({ version: r.version, commits: r.commits.length ? commitDiffs(r.commits, r.range) : {} }));
    }
    const from = r.prev || EMPTY_TREE, to = r.tag || head;
    const stats = numstat(git('diff', '--numstat', '-M', from, to));
    netOf.set(r.version, { files: stats.length, adds: stats.reduce((n, f) => n + f.adds, 0), dels: stats.reduce((n, f) => n + f.dels, 0) });
    const diff = 'diff-' + fileName(r.version) + '.json';
    if (!(r.tag && keep(diff))) {
        emit(diff, JSON.stringify({ version: r.version, from: r.prev, to: r.tag || head, files: netDiff(from, to) }));
    }
}

// Each item's work: its commits' diffs together, and each one's own.
for (const item of items) {
    const list = item.commits.map((s) => commits.get(s));
    if (!list.length) { continue; }
    const own = {};
    for (const group of [list.filter((c) => c.release !== WIP), list.filter((c) => c.release === WIP)]) {
        Object.assign(own, commitDiffs(group));
    }
    const combined = combinedDiff(list, own);
    item.work = { files: combined.files.length, adds: combined.adds, dels: combined.dels, exact: combined.exact };
    emit('work-' + item.id + '.json', JSON.stringify({ id: item.id, ...combined, commits: own }));
}

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
        dels: r.commits.reduce((n, c) => n + c.dels, 0), net: netOf.get(r.version),
        sections: note.sections, files: [...files.values()].sort((a, b) => b[1] + b[2] - a[1] - a[2] || (a[0] < b[0] ? -1 : 1)),
    };
})));

emit('comments.json', rows(conversations));

const latest = releases[releases.length - 2];
const board = {
    repo: { url: repoInfo.url || '', name: repoInfo.name || 'ForeverPlusPlus' },
    head: { sha: head, date: commits.get(head) ? commits.get(head).date : null },
    latest: latest ? latest.version : null,
    unreleased: unreleased.commits.length,
    unpushed: unpushed.size,
    remote: hasRemote,
    // What a release needs before it's tagged: the TOC's version and the notes in both places.
    next: {
        toc: tocVersion,
        notes: (notes.get(UNRELEASED) || { sections: [] }).sections.reduce((n, s) => n + s.entries.length, 0),
        gameNotes,
    },
    curseforge: CF_URL,
    sources,
    items,
    branches,
};
const generated = new Date().toISOString();
emit('board.json', JSON.stringify(board), (body) => '{"generated":' + JSON.stringify(generated) + ',' + body.slice(1));

// Files the last run wrote that this one didn't: an item gone, or a file no longer made.
for (const rel of Object.keys(manifest)) {
    if (!next[rel] && /^data\/[\w.-]+\.json$/.test(rel)) { fs.rmSync(path.join(out, rel), { force: true }); }
}
fs.writeFileSync(manifestPath, JSON.stringify(next, null, 1));
let published = {};
try { published = JSON.parse(fs.readFileSync(publishedPath, 'utf8')); } catch { /* never published */ }
const changed = Object.keys(next).filter((rel) => published[rel] !== next[rel]);
const removed = Object.keys(published).filter((rel) => !next[rel]);
console.log(changed.length ? 'CHANGED ' + changed.join(' ') : 'CHANGED (none)');
if (removed.length) { console.log('REMOVED ' + removed.join(' ')); }
