-- Small frame helpers modules share: probing for Blizzard art and templates, the box tooltips are
-- drawn in, red text in the error frame, and running something once after a burst of calls.
local _, ns = ...

local select, CreateFrame, C_Timer = select, CreateFrame, C_Timer

local Frames = {}
ns.Frames = Frames

---Whether this client has an atlas. Probe: atlas names change between builds.
---@param name string
---@return boolean
function Frames.HasAtlas(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) and true or false
end

---The first atlas in the list this client has, or nil.
---@param ... string atlas names, best first
---@return string?
function Frames.FirstAtlas(...)
    for i = 1, select("#", ...) do
        local name = select(i, ...)
        if Frames.HasAtlas(name) then
            return name
        end
    end
end

---Whether this client has a Blizzard template (Mainline's).
---@param name string
---@return boolean
function Frames.HasTemplate(name)
    return C_XMLUtil and C_XMLUtil.GetTemplateInfo and C_XMLUtil.GetTemplateInfo(name) and true
        or false
end

---A frame in the box Blizzard draws tooltips in, or the older tooltip backdrop where this client
---doesn't have the template.
---@param parent table
---@return table
function Frames.TooltipBox(parent)
    local hasTemplate = Frames.HasTemplate("TooltipBackdropTemplate")
    local box = CreateFrame("Frame", nil, parent,
        hasTemplate and "TooltipBackdropTemplate" or "BackdropTemplate")
    if not hasTemplate and box.SetBackdrop and BACKDROP_TOOLTIP_16_16_5555 then
        box:SetBackdrop(BACKDROP_TOOLTIP_16_16_5555)
        box:SetBackdropColor(0, 0, 0, 0.8)
    end
    return box
end

---Red text in the middle of the screen, the way the game says "Not enough rage".
---@param text string?
function Frames.ErrorMessage(text)
    if not (text and UIErrorsFrame) then
        return
    end
    if UIErrorsFrame.AddExternalErrorMessage then
        UIErrorsFrame:AddExternalErrorMessage(text)
    else
        UIErrorsFrame:AddMessage(text, 1, 0.1, 0.1)
    end
end

---Runs `fn` once, `delay` seconds after the first call (the next frame by default), however often
---it's called before then. For events that come in bursts.
---@param fn function
---@param delay? number
---@return function queue call to run `fn` soon
---@return function cancel drops a queued run
function Frames.Coalesce(fn, delay)
    local timer
    local function run()
        timer = nil
        fn()
    end
    local function queue()
        if not timer then
            timer = C_Timer.NewTimer(delay or 0, run)
        end
    end
    local function cancel()
        if timer then
            timer:Cancel()
            timer = nil
        end
    end
    return queue, cancel
end
