-- Helpers for secret values: Forever inherits Midnight's rules, so unit data can come back secret
-- (mostly in combat and instances) and must not be tested or compared in Lua.
local _, ns = ...

local issecretvalue, C_CurveUtil, UnitHealthPercent, Enum = issecretvalue, C_CurveUtil, UnitHealthPercent, Enum

---Whether a value can be tested, compared, or used in Lua. Secret values can't; treat them as
---unknown and pass them only to widget setters.
---@param value any
---@return boolean
function ns.IsReadable(value)
    return not (issecretvalue and issecretvalue(value))
end

---A curve for `UnitHealthPercent(unit, true, curve)` that gives `hurt` below full health and
---`full` at full health. Use the result as an alpha (or other widget value): the client does the
---math, so it works while health is secret. Nil on a client without curves.
---@param hurt number
---@param full number
---@return table?
function ns.HealthStepCurve(hurt, full)
    if not (C_CurveUtil and C_CurveUtil.CreateCurve and UnitHealthPercent) then
        return nil
    end
    local curve = C_CurveUtil.CreateCurve()
    if Enum.LuaCurveType and Enum.LuaCurveType.Step and curve.SetType then
        curve:SetType(Enum.LuaCurveType.Step)
        curve:AddPoint(0, hurt)
        curve:AddPoint(1, full)
    else
        -- A steep ramp just below full, for clients without step curves.
        curve:AddPoint(0, hurt)
        curve:AddPoint(0.99, hurt)
        curve:AddPoint(1, full)
    end
    return curve
end
