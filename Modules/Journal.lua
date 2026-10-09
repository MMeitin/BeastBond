local _, BB = ...
local L = BB.L
local mod = BB:NewModule("Journal")

local TAME_BEAST = 1515 -- Classic spell ID; unverified in Forever. Without it pets are still logged, just not flagged "tamed".
local TAME_WINDOW = 45 -- seconds after a Tame Beast cast during which a new pet counts as tamed

local MAX_STORY = 60 -- chapters kept per pet (the first one is never dropped)
local LEVEL_STEPS = { 10, 20, 30, 40, 50, 60, 70, 80 }
local ZONE_STEPS = { 5, 10, 25 }
local DAY_STEPS = { 7, 30, 100, 365 }
local CARE_STEPS = { 1, 10, 50 }

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

---------------------------------------------------------------------------
-- Story: chapters are added automatically as you spend time with a pet
---------------------------------------------------------------------------
local function AddStory(entry, text)
    entry.story = entry.story or {}
    table.insert(entry.story, { d = date("%Y-%m-%d"), t = text })
    if #entry.story > MAX_STORY then table.remove(entry.story, 2) end
    if BB.RefreshJournal then BB.RefreshJournal() end
end

-- Adds a chapter the first time `value` reaches each step; returns true if any chapter was added
local function Milestone(entry, key, value, steps, fmt)
    entry.ms = entry.ms or {}
    local added = false
    for _, step in ipairs(steps) do
        local flag = key .. step
        if value >= step and not entry.ms[flag] then
            entry.ms[flag] = true
            AddStory(entry, fmt:format(entry.name, step))
            added = true
        end
    end
    return added
end

local function CountKeys(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

local function DaysTogether(entry)
    local now = time()
    return math.floor((now - (entry.since or now)) / 86400)
end

-- days together, times nursed back to health, zones explored, times fallen
function BB:PetStats(entry)
    return DaysTogether(entry), entry.cared or 0, CountKeys(entry.zones), entry.falls or 0
end

-- Returns true when a new entry was added
local function RecordPet(info)
    if not (info and info.name and info.family) then return false end
    local journal = Journal()
    local key = PetKey(info)
    if journal[key] then return false end
    local entry = {
        name = info.name,
        family = info.family,
        level = info.level,
        zone = info.zone,
        date = info.date,
        since = time(),
        tamed = info.tamed or false,
        minutes = 0,
        cared = 0,
        falls = 0,
        zones = {},
        story = {},
        ms = {},
    }
    if info.zone then entry.zones[info.zone] = true end
    -- a pet first seen at level 40 shouldn't instantly "reach" levels 10..40
    for _, step in ipairs(LEVEL_STEPS) do
        if (info.level or 0) >= step then entry.ms["lvl" .. step] = true end
    end
    journal[key] = entry
    if info.tamed then
        AddStory(entry, L.STORY_TAMED:format(info.name, info.zone or "?"))
    else
        AddStory(entry, L.STORY_MET:format(info.name, info.zone or "?", info.level or 0))
    end
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

-- Called by the Guardian when the pet's mood rises from unhappy
function BB:PetCaredFor(entry)
    entry = entry or self:CurrentPetEntry()
    if not entry then return false end
    entry.cared = (entry.cared or 0) + 1
    Milestone(entry, "care", entry.cared, CARE_STEPS, L.STORY_CARED)
    return true
end

local function PetFell(entry, zone)
    entry.falls = (entry.falls or 0) + 1
    AddStory(entry, L.STORY_FELL:format(entry.name, zone or "?"))
end

-- Everything that depends on time spent together (runs once a minute while the pet is out)
local function Tick(entry, pet)
    entry.since = entry.since or time()
    if pet.level and pet.level > (entry.level or 0) then entry.level = pet.level end
    if pet.zone then
        entry.zones = entry.zones or {}
        entry.zones[pet.zone] = true
    end
    Milestone(entry, "lvl", entry.level or 0, LEVEL_STEPS, L.STORY_LEVEL)
    Milestone(entry, "zones", CountKeys(entry.zones), ZONE_STEPS, L.STORY_ZONES)
    Milestone(entry, "days", DaysTogether(entry), DAY_STEPS, L.STORY_DAYS)
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
            if after > before then
                local msg = L.BOND_UP:format(entry.name, bondName)
                BB:Alert(msg)
                AddStory(entry, msg)
            end
            Tick(entry, pet)
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

-- Edge-triggered: one "fallen" chapter per death
local fell
mod:On("UNIT_HEALTH", function(_, _, unit)
    if unit ~= "pet" then return end
    if UnitIsDead("pet") then
        if not fell then
            fell = true
            local entry = BB:CurrentPetEntry()
            if entry then PetFell(entry, GetRealZoneText()) end
        end
    else
        fell = nil
    end
end)

---------------------------------------------------------------------------
-- Journal window
---------------------------------------------------------------------------
local ROW_H = 42
local MEDIA = "Interface\\AddOns\\BeastBond\\Media\\"
-- dark ink colors for the parchment page
local GREEN = "|cff3d5a1e"
local GOLD = "|cff8a5a00"
local RED = "|cff7a1f0a"
local INK = { 0.2, 0.12, 0.05 }
local INK_SOFT = { 0.34, 0.24, 0.12 }
local INK_TITLE = { 0.42, 0.13, 0.05 }

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

-- Plain text version of the list (the export view): select all + copy
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

-- The story of one pet as plain text lines (first line is the title); newest chapter first
local function StoryLines(entry)
    local days, cared, zones, falls = BB:PetStats(entry)
    local _, bond = BB:BondLevel(entry.minutes)
    local lines = {
        ("%s (%s) - %s"):format(entry.name, entry.family, bond),
        ("Together since %s (%d %s)"):format(entry.date or "?", days, days == 1 and "day" or "days"),
        ("Time together: %s"):format(Duration(entry.minutes)),
        ("Nursed back to health: %d   Zones explored: %d   Fallen in battle: %d"):format(cared, zones, falls),
        "",
        "Chapters",
    }
    local story = entry.story or {}
    if #story == 0 then lines[#lines + 1] = "Your story is just beginning." end
    for i = #story, 1, -1 do
        lines[#lines + 1] = ("%s   %s"):format(story[i].d, story[i].t)
    end
    return lines
end

local function StoryText(entry)
    return table.concat(StoryLines(entry), "\n")
end

local frame, rows = nil, {}
local viewing, exporting -- viewing: entry whose story is open; exporting: showing copyable text

local function GetRow(i)
    local row = rows[i]
    if row then return row end
    row = CreateFrame("Button", nil, frame.content)
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
    row:SetPoint("TOPRIGHT", 0, -(i - 1) * ROW_H)
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(0.35, 0.22, 0.08, i % 2 == 0 and 0.10 or 0)
    row.hl = row:CreateTexture(nil, "HIGHLIGHT")
    row.hl:SetAllPoints()
    row.hl:SetColorTexture(0.7, 0.45, 0.1, 0.22)
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetPoint("TOPLEFT", 10, -7)
    row.name:SetTextColor(INK_TITLE[1], INK_TITLE[2], INK_TITLE[3])
    row.family = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.family:SetPoint("TOPRIGHT", -10, -8)
    row.detail = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.detail:SetPoint("BOTTOMLEFT", 10, 7)
    row.detail:SetWidth(200)
    row.detail:SetJustifyH("LEFT")
    row.detail:SetWordWrap(false)
    row.detail:SetTextColor(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3])
    row.rank = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.rank:SetPoint("BOTTOMRIGHT", -10, 7)
    row:SetScript("OnClick", function(self)
        viewing = self.entry
        if BB.RefreshJournal then BB.RefreshJournal() end
    end)
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
        row.entry = e
        row.name:SetText(e.name .. (e.tamed and ("  " .. GOLD .. "(tamed)|r") or ""))
        row.family:SetText(GREEN .. e.family .. "|r")
        local _, bondName = BB:BondLevel(e.minutes)
        row.detail:SetText(("Level %s  -  %s  -  %s"):format(tostring(e.level or "?"), e.zone or "?", e.date or "?"))
        row.rank:SetText(("%s%s  -  %s|r"):format(GOLD, Duration(e.minutes), bondName))
        row:Show()
    end
    for i = #entries + 1, #rows do rows[i]:Hide() end
    frame.content:SetHeight(math.max(1, #entries * ROW_H))

    -- story text: dark title, green section heading, amber dates
    if viewing then
        frame.storyBar:SetBond(viewing.minutes)
        local lines = StoryLines(viewing)
        lines[1] = RED .. lines[1] .. "|r"
        lines[6] = GREEN .. lines[6] .. "|r"
        for i = 7, #lines do
            local d, rest = lines[i]:match("^(%d%d%d%d%-%d%d%-%d%d)%s+(.*)$")
            if d then lines[i] = GOLD .. d .. "|r   " .. rest end
        end
        frame.storyText:SetText(table.concat(lines, "\n"))
        frame.storyContent:SetHeight(frame.storyText:GetStringHeight() + 12)
    end

    -- export text
    if exporting then
        local text = viewing and StoryText(viewing) or BuildText()
        frame.edit.shown = text
        frame.edit:SetText(text)
    end

    -- which view is visible
    local listView = not viewing and not exporting
    frame.scroll:SetShown(listView)
    frame.empty:SetShown(listView and #entries == 0)
    frame.hint:SetShown(listView and #entries > 0)
    frame.storyScroll:SetShown(viewing ~= nil and not exporting)
    frame.storyBar:SetShown(viewing ~= nil and not exporting)
    frame.backButton:SetShown(viewing ~= nil and not exporting)
    frame.exportBox:SetShown(exporting == true)
    frame.exportButton:SetText(exporting and "Back" or "Copy / export")
end
BB.RefreshJournal = RefreshJournal

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
    if frame.TitleText then frame.TitleText:SetText("Hunter's Journal") end

    -- Layers, bottom to top: stone frame, parchment page, header art, scrolling content, buttons.
    -- (a frame's own textures draw below its child frames, so each layer is its own frame)
    local base = frame.Inset and frame.Inset:GetFrameLevel() or frame:GetFrameLevel()
    local page = CreateFrame("Frame", nil, frame)
    if frame.Inset then
        page:SetAllPoints(frame.Inset)
    else
        page:SetPoint("TOPLEFT", 8, -28)
        page:SetPoint("BOTTOMRIGHT", -8, 38)
    end
    page:SetFrameLevel(base + 1)
    page.tex = page:CreateTexture(nil, "BACKGROUND")
    page.tex:SetAllPoints()
    page.tex:SetTexture(MEDIA .. "parchment.tga")

    local top = CreateFrame("Frame", nil, frame)
    top:SetAllPoints(page)
    top:SetFrameLevel(base + 2)

    -- header: paw icon in a gold ring, character, totals, families
    frame.icon = top:CreateTexture(nil, "ARTWORK")
    frame.icon:SetSize(34, 34)
    frame.icon:SetPoint("TOPLEFT", 28, -20)
    frame.icon:SetTexture("Interface\\Icons\\Ability_Hunter_BeastCall")
    frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local ring = top:CreateTexture(nil, "OVERLAY")
    ring:SetSize(56, 56)
    ring:SetPoint("CENTER", frame.icon, "CENTER")
    ring:SetTexture(MEDIA .. "ring.tga")
    frame.heading = top:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.heading:SetPoint("TOPLEFT", ring, "TOPRIGHT", 10, -4)
    frame.heading:SetTextColor(INK_TITLE[1], INK_TITLE[2], INK_TITLE[3])
    frame.stats = top:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.stats:SetPoint("TOPLEFT", frame.heading, "BOTTOMLEFT", 0, -4)
    frame.stats:SetTextColor(INK[1], INK[2], INK[3])
    frame.families = top:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.families:SetPoint("TOPLEFT", frame.stats, "BOTTOMLEFT", 0, -3)
    frame.families:SetPoint("RIGHT", top, "RIGHT", -20, 0)
    frame.families:SetJustifyH("LEFT")

    -- ornamental divider
    local divider = top:CreateTexture(nil, "ARTWORK")
    divider:SetTexture(MEDIA .. "divider.tga")
    divider:SetHeight(16)
    divider:SetPoint("TOPLEFT", 14, -72)
    divider:SetPoint("TOPRIGHT", -14, -72)

    -- a dark rail with a gold edge behind the scrollbar, so the grey arrows look deliberate
    local rail = top:CreateTexture(nil, "BACKGROUND")
    rail:SetColorTexture(0.18, 0.11, 0.05, 0.9)
    rail:SetWidth(22)
    rail:SetPoint("TOPRIGHT", page, "TOPRIGHT", -2, -86)
    rail:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -2, 24)
    local railEdge = top:CreateTexture(nil, "BORDER")
    railEdge:SetColorTexture(0.79, 0.64, 0.15, 0.7)
    railEdge:SetWidth(1)
    railEdge:SetPoint("TOPRIGHT", rail, "TOPLEFT")
    railEdge:SetPoint("BOTTOMRIGHT", rail, "BOTTOMLEFT")

    -- list
    frame.scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    frame.scroll:SetFrameLevel(base + 3)
    frame.scroll:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -92)
    frame.scroll:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -30, 30)
    frame.content = CreateFrame("Frame", nil, frame.scroll)
    frame.content:SetSize(396, 1)
    frame.scroll:SetScrollChild(frame.content)

    -- empty state
    frame.empty = top:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.empty:SetPoint("CENTER", frame.scroll, "CENTER", 0, 10)
    frame.empty:SetWidth(320)
    frame.empty:SetTextColor(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3])
    frame.empty:SetText("No pets recorded yet.\n\nSummon or tame a pet and it will appear here, along with how long you have been together.")

    -- story view
    frame.storyScroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    frame.storyScroll:SetFrameLevel(base + 3)
    frame.storyScroll:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -120)
    frame.storyScroll:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -30, 30)
    frame.storyContent = CreateFrame("Frame", nil, frame.storyScroll)
    frame.storyContent:SetSize(396, 1)
    frame.storyScroll:SetScrollChild(frame.storyContent)
    frame.storyText = frame.storyContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.storyText:SetPoint("TOPLEFT", 4, -2)
    frame.storyText:SetWidth(388)
    frame.storyText:SetJustifyH("LEFT")
    frame.storyText:SetSpacing(3)
    frame.storyText:SetTextColor(INK[1], INK[2], INK[3])
    frame.storyScroll:Hide()
    frame.storyBar = BB:CreateBondBar(frame, 372, 14)
    frame.storyBar:SetFrameLevel(base + 4)
    frame.storyBar:SetPoint("TOPLEFT", page, "TOPLEFT", 24, -98)
    frame.storyBar:Hide()

    -- export view (read-only, selectable text)
    frame.exportBox = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    frame.exportBox:SetFrameLevel(base + 3)
    frame.exportBox:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -92)
    frame.exportBox:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -30, 30)
    frame.edit = CreateFrame("EditBox", nil, frame.exportBox)
    frame.edit:SetMultiLine(true)
    frame.edit:SetFontObject(ChatFontNormal)
    frame.edit:SetTextColor(INK[1], INK[2], INK[3])
    frame.edit:SetWidth(396)
    frame.edit:SetAutoFocus(false)
    frame.edit:SetScript("OnEscapePressed", function() frame:Hide() end)
    frame.edit:SetScript("OnTextChanged", function(self, byUser)
        if byUser then self:SetText(self.shown or "") end
    end)
    frame.exportBox:SetScrollChild(frame.edit)
    frame.exportBox:Hide()

    frame.exportButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.exportButton:SetFrameLevel(base + 4)
    frame.exportButton:SetSize(130, 24)
    frame.exportButton:SetPoint("BOTTOMLEFT", 16, 14)
    frame.exportButton:SetText("Copy / export")
    frame.exportButton:SetScript("OnClick", function()
        exporting = not exporting
        RefreshJournal()
        if exporting then
            frame.edit:HighlightText()
            frame.edit:SetFocus()
        end
    end)

    frame.backButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.backButton:SetFrameLevel(base + 4)
    frame.backButton:SetSize(130, 24)
    frame.backButton:SetPoint("BOTTOMRIGHT", -16, 14)
    frame.backButton:SetText("Back to journal")
    frame.backButton:SetScript("OnClick", function()
        viewing = nil
        RefreshJournal()
    end)
    frame.backButton:Hide()

    frame.hint = top:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.hint:SetPoint("BOTTOM", page, "BOTTOM", 0, 10)
    frame.hint:SetTextColor(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3])
    frame.hint:SetText("Click a pet to read your story together")

    frame:SetScript("OnHide", function()
        viewing, exporting = nil, nil
        RefreshJournal()
    end)
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
        viewing, exporting = nil, nil
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

-- Fresh fake pet, then feed it simulated progress. Returns the entry and whether any chapter was added.
local function StoryRun(entry)
    local added = false
    local function step(key, value, steps, fmt)
        added = Milestone(entry, key, value, steps, fmt) or added
    end
    step("lvl", 20, LEVEL_STEPS, L.STORY_LEVEL)
    step("zones", 10, ZONE_STEPS, L.STORY_ZONES)
    step("days", 30, DAY_STEPS, L.STORY_DAYS)
    entry.cared = 10
    step("care", 10, CARE_STEPS, L.STORY_CARED)
    return added
end

local function FreshFake()
    Journal()["Test Boar|Boar"] = nil
    RecordPet(FakePet("Test Boar"))
    return Journal()["Test Boar|Boar"]
end

BB:RegisterTest("story", function()
    local entry = FreshFake()
    entry.minutes = 250
    PetFell(entry, "Test Zone")
    local added = StoryRun(entry)
    viewing = entry
    local ok = pcall(ShowJournal)
    return ok and added
end, true)
BB:RegisterTest("storyrepeat", function() -- the same progress must not add chapters twice
    local entry = FreshFake()
    StoryRun(entry)
    return StoryRun(entry)
end, false)
