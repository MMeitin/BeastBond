local _, BB = ...
local L = BB.L
local mod = BB:NewModule("Guardian")

local ALERT_COOLDOWN = 30 -- seconds before the same alert can repeat

-- Happiness: 1 unhappy, 2 content, 3 happy (Classic convention; verify with a real pet via /bb debug).
local lastHappiness

-- `sim` overrides real game state so every path can be exercised without a pet (/bb test ...).
local sim

local function Happiness()
    if sim and sim.happiness then return sim.happiness end
    return BB:GetHappiness()
end

local function PetName()
    if sim and sim.name then return sim.name end
    return UnitName("pet") or L.PET_FALLBACK
end

local function PetExists()
    if sim and sim.pet ~= nil then return sim.pet end
    return UnitExists("pet")
end

local function PetDead()
    if sim and sim.dead ~= nil then return sim.dead end
    return UnitIsDead("pet")
end

-- Hunter >= 10 who actually owns a pet (stable API missing => assume yes)
local function ShouldHavePet()
    if sim and sim.force then return true end
    local _, class = UnitClass("player")
    if class ~= "HUNTER" or UnitLevel("player") < 10 then return false end
    if C_StableInfo and C_StableInfo.GetNumActivePets then
        local n = C_StableInfo.GetNumActivePets()
        if type(n) == "number" then return n > 0 end
    end
    return true
end

-- Returns true when an alert was actually shown (false: nothing to say or throttled)
local function CheckHappiness()
    if not PetExists() then lastHappiness = nil return false end
    local h = Happiness()
    if type(h) ~= "number" or h == lastHappiness then return false end
    local shown = false
    if h == 1 then
        shown = BB:Alert(L.PET_UNHAPPY:format(PetName()), ALERT_COOLDOWN)
    elseif h == 2 and lastHappiness == 3 then
        shown = BB:Alert(L.PET_HUNGRY:format(PetName()), ALERT_COOLDOWN)
    end
    lastHappiness = h
    return shown
end

local function CheckPet()
    if not BB.db.missingPetAlert then return false end
    if not (sim and sim.force) then
        if InCombatLockdown() or UnitIsDeadOrGhost("player") or IsMounted() or UnitOnTaxi("player") then
            return false
        end
    end
    if not ShouldHavePet() then return false end
    if PetExists() and PetDead() then
        return BB:Alert(L.PET_DEAD:format(PetName()), ALERT_COOLDOWN)
    elseif not PetExists() then
        return BB:Alert(L.PET_MISSING, ALERT_COOLDOWN)
    end
    return false
end

function mod:OnEnable()
    -- Poll as a fallback in case the happiness event doesn't fire in this client
    self.ticker = C_Timer.NewTicker(20, CheckHappiness)
end

function mod:OnDisable()
    if self.ticker then self.ticker:Cancel() self.ticker = nil end
end

mod:On("UNIT_HAPPINESS", CheckHappiness)
mod:On("UNIT_PET", function(_, _, unit)
    if unit == "player" then
        CheckHappiness()
        C_Timer.After(1, CheckPet)
    end
end)
mod:On("PLAYER_ENTERING_WORLD", function()
    C_Timer.After(3, CheckPet)
end)
mod:On("PLAYER_REGEN_ENABLED", CheckPet)

---------------------------------------------------------------------------
-- /bb test <state>: runs the real check with fake state, reports whether it fired
---------------------------------------------------------------------------
local function Simulate(state, previousHappiness, check)
    lastHappiness, sim = previousHappiness, state
    local result = check()
    sim, lastHappiness = nil, nil
    return result
end

-- "happy" must stay silent; the others must alert
BB:RegisterTest("unhappy", function() return Simulate({ happiness = 1, pet = true, name = "Rex" }, nil, CheckHappiness) end, true)
BB:RegisterTest("content", function() return Simulate({ happiness = 2, pet = true, name = "Rex" }, 3, CheckHappiness) end, true)
BB:RegisterTest("happy", function() return Simulate({ happiness = 3, pet = true, name = "Rex" }, nil, CheckHappiness) end, false)
BB:RegisterTest("dead", function() return Simulate({ pet = true, dead = true, force = true, name = "Rex" }, nil, CheckPet) end, true)
BB:RegisterTest("missing", function() return Simulate({ pet = false, force = true }, nil, CheckPet) end, true)
