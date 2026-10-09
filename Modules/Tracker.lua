local _, BB = ...
local L = BB.L
local mod = BB:NewModule("Tracker")

local MAX_SEEN = 200
local seen, seenCount = {}, 0

-- Snapshot of what we need from a unit token (also the shape /bb test feeds in)
local function ReadUnit(unit)
    if not UnitExists(unit) or UnitIsPlayer(unit) or UnitIsDead(unit) then return end
    return {
        guid = UnitGUID(unit),
        name = UnitName(unit),
        family = UnitCreatureFamily(unit), -- non-nil only for creatures that belong to a pet family
        classification = UnitClassification(unit),
        level = UnitLevel(unit),
    }
end

local function CreatureID(guid)
    return tonumber((select(6, strsplit("-", guid))))
end

-- Returns true when an alert was shown
local function Evaluate(info)
    if not (info and info.guid and info.family) then return false end
    if info.classification ~= "rare" and info.classification ~= "rareelite" then return false end
    if seen[info.guid] then return false end
    if seenCount >= MAX_SEEN then wipe(seen) seenCount = 0 end
    seen[info.guid] = true
    seenCount = seenCount + 1

    local msg = L.TAME_FOUND:format(info.name or "?", info.family, info.level or 0)
    local known = BB.Tames[CreatureID(info.guid) or 0]
    if known then
        if known.skin then msg = msg .. " - " .. known.skin end
        if known.note then msg = msg .. " (" .. known.note .. ")" end
    end
    BB:Debug("tame guid", info.guid)
    return BB:Alert(msg)
end

local function CheckUnit(unit)
    if not BB.db.tameAlert then return end
    local _, class = UnitClass("player")
    if class ~= "HUNTER" or IsInInstance() then return end
    Evaluate(ReadUnit(unit))
end

mod:On("PLAYER_TARGET_CHANGED", function() CheckUnit("target") end)
mod:On("NAME_PLATE_UNIT_ADDED", function(_, _, unit) CheckUnit(unit) end)

local function Simulate(info)
    wipe(seen) seenCount = 0
    local result = Evaluate(info)
    wipe(seen) seenCount = 0
    return result
end

local FAKE_GUID = "Creature-0-0-0-0-99999-0000000000"
BB:RegisterTest("tame", function()
    return Simulate({ guid = FAKE_GUID, name = "Test Rare Boar", family = "Boar", classification = "rare", level = 12 })
end, true)
BB:RegisterTest("tamecommon", function() -- a normal beast must stay silent
    return Simulate({ guid = FAKE_GUID, name = "Test Boar", family = "Boar", classification = "normal", level = 12 })
end, false)
BB:RegisterTest("tamerepeat", function() -- same creature must alert only once
    wipe(seen) seenCount = 0
    local info = { guid = FAKE_GUID, name = "Test Rare Boar", family = "Boar", classification = "rare", level = 12 }
    Evaluate(info)
    BB:ResetThrottle()
    local second = Evaluate(info)
    wipe(seen) seenCount = 0
    return second
end, false)
