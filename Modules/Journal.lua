local _, BB = ...
local L = BB.L
local mod = BB:NewModule("Journal")

local TAME_BEAST = 1515 -- Classic spell ID; unverified in Forever. Without it pets are still logged, just not flagged "tamed".
local TAME_WINDOW = 45 -- seconds after a Tame Beast cast during which a new pet counts as tamed

local tameStarted

local function CharKey()
    return UnitName("player") .. "-" .. GetRealmName()
end

-- Journal of the current character: { [petKey] = entry } (entries are plain tables, safe to save)
local function Journal()
    local all = BB.db.journal
    local key = CharKey()
    all[key] = all[key] or {}
    return all[key]
end

local function PetKey(info)
    return info.name .. "|" .. info.family
end

-- Returns true when a new entry was added
local function RecordPet(info)
    if not (info and info.name and info.family) then return false end
    local journal = Journal()
    local key = PetKey(info)
    if journal[key] then return false end
    journal[key] = {
        name = info.name,
        family = info.family,
        level = info.level,
        zone = info.zone,
        date = info.date,
        tamed = info.tamed or false,
        minutes = 0,
    }
    BB:Print(L.JOURNAL_NEW:format(info.name, info.family))
    if BB.RefreshJournal then BB.RefreshJournal() end
    return true
end

local function ReadPet()
    if not UnitExists("pet") then return end
    local name, family = UnitName("pet"), UnitCreatureFamily("pet")
    if not (name and family) then return end
    return {
        name = name,
        family = family,
        level = UnitLevel("pet"),
        zone = GetRealZoneText(),
        date = date("%Y-%m-%d"),
        tamed = tameStarted ~= nil and (GetTime() - tameStarted) < TAME_WINDOW,
    }
end

local function CheckPet()
    RecordPet(ReadPet())
end

-- Journal entry of the pet that is out right now (nil if none)
function BB:CurrentPetEntry()
    local pet = ReadPet()
    return pet and Journal()[PetKey(pet)]
end

function mod:OnEnable()
    -- time together: one tick per minute while the pet is out
    self.ticker = C_Timer.NewTicker(60, function()
        local pet = ReadPet()
        local entry = pet and Journal()[PetKey(pet)]
        if entry then
            local before = BB:BondLevel(entry.minutes)
            entry.minutes = (entry.minutes or 0) + 1
            local after, bondName = BB:BondLevel(entry.minutes)
            if after > before then BB:Alert(L.BOND_UP:format(entry.name, bondName)) end
            if BB.RefreshCard then BB.RefreshCard() end
        end
    end)
end

function mod:OnDisable()
    if self.ticker then self.ticker:Cancel() self.ticker = nil end
end

local function OnTameCast(_, _, unit, _, spellID)
    if unit == "player" and spellID == TAME_BEAST then tameStarted = GetTime() end
end
mod:On("UNIT_SPELLCAST_CHANNEL_START", OnTameCast)
mod:On("UNIT_SPELLCAST_SUCCEEDED", OnTameCast)
mod:On("UNIT_PET", function(_, _, unit)
    if unit == "player" then C_Timer.After(1, CheckPet) end
end)
mod:On("PLAYER_ENTERING_WORLD", function() C_Timer.After(3, CheckPet) end)

---------------------------------------------------------------------------
-- Journal window
---------------------------------------------------------------------------
local ROW_H = 42
local GREEN = "|cffabd473"
local GOLD = "|cffffd100"

local function SortedEntries()
    local entries = {}
    for _, e in pairs(Journal()) do entries[#entries + 1] = e end
    table.sort(entries, function(a, b)
        if a.family ~= b.family then return a.family < b.family end
        return a.name < b.name
    end)
    return entries
end

local function FamilySummary(entries)
    local counts, order = {}, {}
    for _, e in ipairs(entries) do
        if not counts[e.family] then counts[e.family] = 0 order[#order + 1] = e.family end
        counts[e.family] = counts[e.family] + 1
    end
    local parts = {}
    for _, f in ipairs(order) do parts[#parts + 1] = ("%s (%d)"):format(f, counts[f]) end
    return #order, table.concat(parts, ", ")
end

local function Duration(mins)
    mins = mins or 0
    return ("%dh %02dm"):format(math.floor(mins / 60), mins % 60)
end

-- Plain text version (the export view): select all + copy
local function BuildText()
    local entries = SortedEntries()
    local nFamilies, summary = FamilySummary(entries)
    local lines = {
        ("BeastBond journal - %s"):format(CharKey()),
        ("Pets: %d   Families: %d"):format(#entries, nFamilies),
        nFamilies > 0 and summary or "No pets recorded yet.",
        "",
    }
    for _, e in ipairs(entries) do
        lines[#lines + 1] = ("%s | %s | lvl %s | %s | %s | %s%s"):format(
            e.name, e.family, tostring(e.level or "?"), e.zone or "?", e.date or "?",
            Duration(e.minutes), e.tamed and " | tamed" or "")
    end
    return table.concat(lines, "\n")
end

local frame, rows = nil, {}

local function GetRow(i)
    local row = rows[i]
    if row then return row end
    row = CreateFrame("Frame", nil, frame.content)
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
    row:SetPoint("TOPRIGHT", 0, -(i - 1) * ROW_H)
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(1, 1, 1, i % 2 == 0 and 0.05 or 0)
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetPoint("TOPLEFT", 10, -7)
    row.family = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.family:SetPoint("TOPRIGHT", -10, -8)
    row.detail = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.detail:SetPoint("BOTTOMLEFT", 10, 7)
    rows[i] = row
    return row
end

local function RefreshJournal()
    if not frame then return end
    local entries = SortedEntries()
    local nFamilies, summary = FamilySummary(entries)

    frame.heading:SetText(UnitName("player"))
    frame.stats:SetText(("%d %s   -   %d %s"):format(
        #entries, #entries == 1 and "pet" or "pets", nFamilies, nFamilies == 1 and "family" or "families"))
    frame.families:SetText(nFamilies > 0 and (GREEN .. summary .. "|r") or "")

    for i, e in ipairs(entries) do
        local row = GetRow(i)
        row.name:SetText(e.name .. (e.tamed and ("  " .. GOLD .. "(tamed)|r") or ""))
        row.family:SetText(GREEN .. e.family .. "|r")
        local _, bondName = BB:BondLevel(e.minutes)
        row.detail:SetText(("Level %s   -   %s   -   %s   -   %s together   -   %s"):format(
            tostring(e.level or "?"), e.zone or "?", e.date or "?", Duration(e.minutes), bondName))
        row:Show()
    end
    for i = #entries + 1, #rows do rows[i]:Hide() end
    frame.content:SetHeight(math.max(1, #entries * ROW_H))
    frame.empty:SetShown(#entries == 0)
    if frame.exportBox:IsShown() then
        local text = BuildText()
        frame.edit.shown = text
        frame.edit:SetText(text)
    end
end
BB.RefreshJournal = RefreshJournal

local function SetExportMode(on)
    frame.exportBox:SetShown(on)
    frame.scroll:SetShown(not on)
    frame.exportButton:SetText(on and "Back to list" or "Copy / export")
    if on then
        local text = BuildText()
        frame.edit.shown = text
        frame.edit:SetText(text)
        frame.edit:HighlightText()
        frame.edit:SetFocus()
        frame.empty:Hide()
    else
        RefreshJournal()
    end
end

local function BuildFrame()
    frame = CreateFrame("Frame", "BeastBondJournal", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(460, 400)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    if frame.TitleText then frame.TitleText:SetText("BeastBond Journal") end

    -- header: paw icon, character, totals, families
    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetSize(40, 40)
    frame.icon:SetPoint("TOPLEFT", 18, -36)
    frame.icon:SetTexture("Interface\\Icons\\Ability_Hunter_BeastCall")
    frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    frame.heading = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.heading:SetPoint("TOPLEFT", frame.icon, "TOPRIGHT", 10, -2)
    frame.stats = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.stats:SetPoint("TOPLEFT", frame.heading, "BOTTOMLEFT", 0, -4)
    frame.families = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.families:SetPoint("TOPLEFT", frame.icon, "BOTTOMLEFT", 0, -8)
    frame.families:SetPoint("RIGHT", frame, "RIGHT", -18, 0)
    frame.families:SetJustifyH("LEFT")

    -- divider
    local line = frame:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(0.79, 0.64, 0.15, 0.6)
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", 14, -104)
    line:SetPoint("TOPRIGHT", -14, -104)

    -- list
    frame.scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    frame.scroll:SetPoint("TOPLEFT", 14, -110)
    frame.scroll:SetPoint("BOTTOMRIGHT", -34, 46)
    frame.content = CreateFrame("Frame", nil, frame.scroll)
    frame.content:SetSize(396, 1)
    frame.scroll:SetScrollChild(frame.content)

    -- empty state
    frame.empty = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    frame.empty:SetPoint("CENTER", frame.scroll, "CENTER", 0, 10)
    frame.empty:SetWidth(320)
    frame.empty:SetText("No pets recorded yet.\n\nSummon or tame a pet and it will appear here, along with how long you have been together.")

    -- export view (read-only, selectable text)
    frame.exportBox = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    frame.exportBox:SetPoint("TOPLEFT", 14, -110)
    frame.exportBox:SetPoint("BOTTOMRIGHT", -34, 46)
    frame.edit = CreateFrame("EditBox", nil, frame.exportBox)
    frame.edit:SetMultiLine(true)
    frame.edit:SetFontObject(ChatFontNormal)
    frame.edit:SetWidth(396)
    frame.edit:SetAutoFocus(false)
    frame.edit:SetScript("OnEscapePressed", function() frame:Hide() end)
    frame.edit:SetScript("OnTextChanged", function(self, byUser)
        if byUser then self:SetText(self.shown or "") end
    end)
    frame.exportBox:SetScrollChild(frame.edit)
    frame.exportBox:Hide()

    frame.exportButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.exportButton:SetSize(130, 24)
    frame.exportButton:SetPoint("BOTTOMLEFT", 16, 14)
    frame.exportButton:SetText("Copy / export")
    frame.exportButton:SetScript("OnClick", function() SetExportMode(not frame.exportBox:IsShown()) end)

    frame:SetScript("OnHide", function() SetExportMode(false) end)
    table.insert(UISpecialFrames, "BeastBondJournal")
    frame:Hide()
end

local function ShowJournal()
    if not frame then BuildFrame() end
    RefreshJournal()
    frame:Show()
end

BB:RegisterCommand("journal", function(self, arg)
    arg = arg:lower()
    if arg == "reset confirm" then
        self.db.journal[CharKey()] = nil
        self:Print("journal cleared for " .. CharKey())
        RefreshJournal()
        return
    elseif arg == "reset" then
        self:Print("this deletes this character's journal. Type /bb journal reset confirm")
        return
    end
    local ok, err = pcall(ShowJournal)
    if not ok then self:Print("could not open the journal: " .. tostring(err)) end
end, "open the pet journal; 'reset' clears it")

---------------------------------------------------------------------------
-- Tests
---------------------------------------------------------------------------
local function FakePet(name)
    return { name = name, family = "Boar", level = 5, zone = "Test Zone", date = "2026-01-01", tamed = true }
end

BB:RegisterTest("tamed", function() return RecordPet(FakePet("Test Boar")) end, true)
BB:RegisterTest("tamedrepeat", function() -- the same pet must not be added twice
    RecordPet(FakePet("Test Boar"))
    return RecordPet(FakePet("Test Boar"))
end, false)
