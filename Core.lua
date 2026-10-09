local ADDON, BB = ...
_G.BeastBond = BB
local L = BB.L

local DB_VERSION = 1

BB.defaults = {
    alertSound = true,
    alertText = true,
    feedReminder = true,
    missingPetAlert = true,
    lockFeedButton = false,
    tameAlert = true,
    showCard = true,
    journal = {}, -- [character-realm] = { [pet key] = entry }
    debug = false,
    modules = {}, -- [name] = false disables a module
}

BB.modules = {}
BB.handlers = {}
BB.commands = {}

local frame = CreateFrame("Frame")
BB.frame = frame

---------------------------------------------------------------------------
-- Output
---------------------------------------------------------------------------
function BB:Print(msg)
    print("|cff88cc44BeastBond|r: " .. msg)
end

function BB:Debug(...)
    if self.db and self.db.debug then
        self:Print("|cff999999[debug]|r " .. strjoin(" ", tostringall(...)))
    end
end

BB.lastAlert = {}

function BB:ResetThrottle()
    wipe(self.lastAlert)
end

-- throttle (seconds, optional): suppress the same message if shown more recently than that.
-- Returns true when the alert was shown.
function BB:Alert(msg, throttle)
    if throttle then
        local now = GetTime()
        local last = self.lastAlert[msg]
        if last and now - last < throttle then return false end
        self.lastAlert[msg] = now
    end
    if self.db.alertText then
        RaidNotice_AddMessage(RaidWarningFrame, msg, ChatTypeInfo["RAID_WARNING"])
        self:Print(msg)
    end
    if self.db.alertSound then
        PlaySound(SOUNDKIT.RAID_WARNING)
    end
    return true
end

---------------------------------------------------------------------------
-- Events: handlers run inside pcall so one bad module can't break the others
---------------------------------------------------------------------------
function BB:On(event, fn, mod)
    local list = self.handlers[event]
    if not list then
        list = {}
        self.handlers[event] = list
    end
    list[#list + 1] = { fn = fn, mod = mod }
    -- pcall: an event missing in this client must not break the addon
    pcall(frame.RegisterEvent, frame, event)
end

frame:SetScript("OnEvent", function(_, event, ...)
    local list = BB.handlers[event]
    if not list then return end
    for _, h in ipairs(list) do
        if not h.mod or h.mod.enabled then
            local ok, err = pcall(h.fn, h.mod or BB, event, ...)
            if not ok then geterrorhandler()(err) end
        end
    end
end)

---------------------------------------------------------------------------
-- Modules
---------------------------------------------------------------------------
local Module = {}
Module.__index = Module

function Module:On(event, fn)
    BB:On(event, fn, self)
end

function Module:SetEnabled(on)
    on = not not on
    BB.db.modules[self.name] = on
    if on == self.enabled then return end
    self.enabled = on
    local fn = on and self.OnEnable or self.OnDisable
    if fn then fn(self) end
end

function BB:NewModule(name)
    local mod = setmetatable({ name = name, enabled = true }, Module)
    self.modules[name] = mod
    return mod
end

---------------------------------------------------------------------------
-- Saved variables
---------------------------------------------------------------------------
function BB:MigrateDB()
    local db = self.db
    for k, v in pairs(self.defaults) do
        if db[k] == nil then
            db[k] = type(v) == "table" and CopyTable(v) or v
        end
    end
    -- Future schema changes: if db.version < 2 then ... end
    db.version = DB_VERSION
end

BB:On("ADDON_LOADED", function(self, _, name)
    if name ~= ADDON then return end
    BeastBondDB = BeastBondDB or {}
    self.db = BeastBondDB
    self:MigrateDB()
    frame:UnregisterEvent("ADDON_LOADED")
end)

BB:On("PLAYER_LOGIN", function(self)
    for name, mod in pairs(self.modules) do
        mod.enabled = self.db.modules[name] ~= false
        if mod.enabled and mod.OnEnable then mod:OnEnable() end
    end
end)

---------------------------------------------------------------------------
-- Pet API helper (number or table depending on build)
---------------------------------------------------------------------------
function BB:GetHappiness()
    if not (C_PetInfo and C_PetInfo.GetPetHappiness) then return end
    local h = C_PetInfo.GetPetHappiness()
    if type(h) == "table" then h = h.happiness or h[1] end
    return h
end

-- Re-evaluate everything that depends on a setting (called when a checkbox changes)
function BB:RefreshAll()
    if self.RefreshCard then self.RefreshCard() end
    if self.RefreshFeed then self.RefreshFeed() end
end

-- Bond: how well you know a pet, from minutes spent together
BB.BOND_STEPS = { 0, 60, 300, 1200, 3000 }

-- Returns level (1..5), level name, progress toward the next level (0..1), minutes needed for the next level
function BB:BondLevel(minutes)
    minutes = minutes or 0
    local level = 1
    for i, m in ipairs(self.BOND_STEPS) do
        if minutes >= m then level = i end
    end
    local from, to = self.BOND_STEPS[level], self.BOND_STEPS[level + 1]
    local progress = to and (minutes - from) / (to - from) or 1
    return level, L.BOND[level], progress, to
end

BB.MEDIA = "Interface\\AddOns\\BeastBond\\Media\\"
local BAR_GREEN = { 0.45, 0.8, 0.35 }
local BAR_GOLD = { 1, 0.82, 0.2 } -- Soulbound

-- Bond bar: dark backing, tinted glossy fill, gold groove on top, rank on the left, minutes to the next rank on the right
function BB:CreateBondBar(parent, width, height)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(width, height)
    bar:SetStatusBarTexture(self.MEDIA .. "barfill.tga")
    bar:SetMinMaxValues(0, 1)
    bar.back = bar:CreateTexture(nil, "BACKGROUND")
    bar.back:SetAllPoints()
    bar.back:SetTexture(self.MEDIA .. "barback.tga")
    bar.groove = bar:CreateTexture(nil, "OVERLAY", nil, 1)
    bar.groove:SetPoint("TOPLEFT", -6, 5)
    bar.groove:SetPoint("BOTTOMRIGHT", 6, -5)
    bar.groove:SetTexture(self.MEDIA .. "barframe.tga")
    bar.rank = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.rank:SetPoint("LEFT", 6, 0)
    bar.rank:SetDrawLayer("OVERLAY", 3)
    bar.remaining = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.remaining:SetPoint("RIGHT", -6, 0)
    bar.remaining:SetDrawLayer("OVERLAY", 3)
    bar.SetBond = function(b, minutes)
        local level, name, progress, nextAt = BB:BondLevel(minutes)
        local tint = level == #BB.BOND_STEPS and BAR_GOLD or BAR_GREEN
        b:SetStatusBarColor(tint[1], tint[2], tint[3])
        b:SetValue(progress)
        b.rank:SetText(name)
        b.remaining:SetText(nextAt and ((nextAt - (minutes or 0)) .. " min") or "")
    end
    return bar
end

---------------------------------------------------------------------------
-- Slash commands: /bb [command] [args]
---------------------------------------------------------------------------
function BB:RegisterCommand(name, fn, help)
    self.commands[name] = { fn = fn, help = help }
end

local function Fmt(v)
    if type(v) == "table" then
        local parts = {}
        for k, val in pairs(v) do parts[#parts + 1] = tostring(k) .. "=" .. tostring(val) end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return tostring(v)
end

local function Show(label, ok, ...)
    local out
    if not ok then
        out = "ERROR " .. tostring((...))
    elseif select("#", ...) == 0 then
        out = "<no return>"
    else
        local vals = {}
        for i = 1, select("#", ...) do vals[i] = Fmt((select(i, ...))) end
        out = table.concat(vals, ", ")
    end
    BB:Print(label .. ": " .. out)
end

local function Call(label, fn)
    if type(fn) ~= "function" then
        BB:Print(label .. ": <missing API>")
    else
        Show(label, pcall(fn))
    end
end

local function Meta(key)
    local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return get and get(ADDON, key)
end

local function GetVersion()
    local v = Meta("Version") or "?"
    -- the packager replaces @project-version@; a dev checkout keeps the literal token
    return v:find("^@") and "dev" or v
end

BB:RegisterCommand("debug", function(self, arg)
    arg = arg:lower()
    if arg == "on" or arg == "off" then
        self.db.debug = (arg == "on")
        self:Print("debug " .. arg)
        return
    end
    local P = C_PetInfo or {}
    self:Print(("addon %s, build %s, class %s, level %s, pet %s"):format(
        GetVersion(), tostring(select(4, GetBuildInfo())), tostring(select(2, UnitClass("player"))),
        tostring(UnitLevel("player")), tostring(UnitExists("pet"))))
    Call("GetPetHappiness", P.GetPetHappiness)
    Call("GetPetLoyalty", P.GetPetLoyalty)
    Call("GetPetFoodTypes", P.GetPetFoodTypes)
end, "dump pet API values; 'debug on|off' toggles verbose logging")

BB:RegisterCommand("about", function(self)
    self:Print(("v%s - hunter pet guardian for WoW: Forever"):format(GetVersion()))
    local site, donate = Meta("X-Website"), Meta("X-Donate")
    if site then print("  Feedback & bug reports: " .. site .. "/issues") end
    if donate then print("  Support the project: " .. donate) end
    print("  Please include the output of /bb debug in bug reports.")
end, "version, feedback and support links")

BB:RegisterCommand("module", function(self, arg)
    local name, state = arg:match("^(%S+)%s*(%S*)$")
    local mod = name and self.modules[name]
    if not mod then
        local names = {}
        for n in pairs(self.modules) do names[#names + 1] = n end
        table.sort(names)
        self:Print("modules: " .. table.concat(names, ", "))
        return
    end
    if state == "on" or state == "off" then mod:SetEnabled(state == "on") end
    self:Print(name .. ": " .. (mod.enabled and "on" or "off"))
end, "show or toggle a module: module <name> on|off")

-- Tests: modules register a state simulation; fn returns true if the feature triggered.
-- `expect` is what a correct build should return, so /bb test can flag regressions.
BB.tests = {}

function BB:RegisterTest(name, fn, expect)
    self.tests[name] = { fn = fn, expect = expect }
end

BB:RegisterCommand("test", function(self, arg)
    local name = arg:lower()
    local t = self.tests[name]
    if not t then
        local names = {}
        for n in pairs(self.tests) do names[#names + 1] = n end
        table.sort(names)
        self:Print("usage: /bb test " .. table.concat(names, "|"))
        return
    end
    self:ResetThrottle()
    local result = not not t.fn()
    self:Print(("test %s: %s (%s)"):format(name, result and "triggered" or "not triggered",
        result == t.expect and "as expected" or "UNEXPECTED"))
end, "simulate a state without a pet (see /bb test)")

BB:RegisterCommand("help", function(self)
    self:Print("commands:")
    local names = {}
    for n in pairs(self.commands) do names[#names + 1] = n end
    table.sort(names)
    for _, n in ipairs(names) do
        print("  /bb " .. n .. " - " .. (self.commands[n].help or ""))
    end
end, "list commands")

SLASH_BEASTBOND1 = "/bb"
SLASH_BEASTBOND2 = "/beastbond"
SlashCmdList.BEASTBOND = function(msg)
    local cmd, rest = (msg or ""):match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()
    if cmd == "" then
        if BB.OpenOptions then BB:OpenOptions() end
        return
    end
    local c = BB.commands[cmd]
    if c then c.fn(BB, rest) else BB.commands.help.fn(BB) end
end
