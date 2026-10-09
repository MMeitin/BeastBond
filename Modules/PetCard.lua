local _, BB = ...
local L = BB.L
local mod = BB:NewModule("PetCard")

local DEFAULT_POINT = { "CENTER", "CENTER", -320, -180 }

-- Same mood faces the default pet UI uses (one texture strip: happy | content | unhappy)
local FACE_TEXTURE = "Interface\\PetPaperDollFrame\\UI-PetHappiness"
local FACE_COORDS = { [1] = { 0.375, 0.5625 }, [2] = { 0.1875, 0.375 }, [3] = { 0, 0.1875 } }
local MOOD_COLORS = { [1] = "|cffe64035", [2] = "|cffffd100", [3] = "|cff59d959" }

-- `sim` fakes a pet for /bb test card (cleared automatically)
local sim

local card = CreateFrame("Frame", "BeastBondCard", UIParent, "BackdropTemplate")
card:SetSize(236, 70)
card:SetFrameStrata("MEDIUM")
card:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 14,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
card:SetBackdropColor(0.05, 0.05, 0.05, 0.85)
card:SetBackdropBorderColor(0.79, 0.64, 0.15, 1)
card:Hide()

card.portrait = card:CreateTexture(nil, "ARTWORK")
card.portrait:SetSize(46, 46)
card.portrait:SetPoint("LEFT", 10, 0)

card.name = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
card.name:SetPoint("TOPLEFT", card.portrait, "TOPRIGHT", 10, -1)

card.face = card:CreateTexture(nil, "ARTWORK")
card.face:SetSize(16, 16)
card.face:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -3)
card.face:SetTexture(FACE_TEXTURE)

card.mood = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
card.mood:SetPoint("LEFT", card.face, "RIGHT", 4, 0)

card.bar = CreateFrame("StatusBar", nil, card)
card.bar:SetSize(150, 12)
card.bar:SetPoint("BOTTOMLEFT", card.portrait, "BOTTOMRIGHT", 10, 0)
card.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
card.bar:SetStatusBarColor(0.67, 0.83, 0.45)
card.bar:SetMinMaxValues(0, 1)
card.bar.bg = card.bar:CreateTexture(nil, "BACKGROUND")
card.bar.bg:SetAllPoints()
card.bar.bg:SetColorTexture(0, 0, 0, 0.55)
card.bar.text = card.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
card.bar.text:SetPoint("CENTER")

-- Shift+drag to move (unless locked); position saved in BeastBondDB.cardPos
card:SetMovable(true)
card:SetClampedToScreen(true)
card:EnableMouse(true)
card:RegisterForDrag("LeftButton")
card:SetScript("OnDragStart", function(self)
    if IsShiftKeyDown() and not BB.db.lockFeedButton then self:StartMoving() end
end)
card:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, rel, x, y = self:GetPoint()
    BB.db.cardPos = { point, rel, x, y }
end)

local function ApplyPosition()
    local p = BB.db.cardPos or DEFAULT_POINT
    card:ClearAllPoints()
    card:SetPoint(p[1], UIParent, p[2], p[3], p[4])
end

function BB:ResetCard()
    self.db.cardPos = nil
    ApplyPosition()
end

local function Update()
    local _, class = UnitClass("player")
    local active = sim or (BB.db.showCard and class == "HUNTER" and UnitExists("pet"))
    if not active then card:Hide() return end

    local name, happiness, minutes
    if sim then
        name, happiness, minutes = sim.name, sim.happiness, sim.minutes
        SetPortraitTexture(card.portrait, "player")
    else
        name, happiness = UnitName("pet"), BB:GetHappiness()
        local entry = BB:CurrentPetEntry()
        minutes = entry and entry.minutes or 0
        SetPortraitTexture(card.portrait, "pet")
    end

    card.name:SetText(name or L.CARD_NO_MOOD)
    local mood = L.HAPPINESS[happiness]
    if mood then
        local c = FACE_COORDS[happiness]
        card.face:SetTexCoord(c[1], c[2], 0, 0.359375)
        card.face:Show()
        card.mood:SetText(MOOD_COLORS[happiness] .. mood .. "|r")
    else
        card.face:Hide()
        card.mood:SetText("")
    end

    local _, bondName, progress, nextAt = BB:BondLevel(minutes)
    card.bar:SetValue(progress)
    card.bar.text:SetText(nextAt and L.BOND_NEXT:format(bondName, nextAt - minutes) or bondName)
    card:Show()
end
BB.RefreshCard = Update

function mod:OnEnable()
    ApplyPosition()
    self.ticker = C_Timer.NewTicker(30, Update)
    Update()
end

function mod:OnDisable()
    if self.ticker then self.ticker:Cancel() self.ticker = nil end
    card:Hide()
end

mod:On("UNIT_PET", function(_, _, unit)
    if unit == "player" then C_Timer.After(1, Update) end
end)
mod:On("UNIT_HAPPINESS", Update)
mod:On("PLAYER_ENTERING_WORLD", function() C_Timer.After(3, Update) end)

-- Shows a made-up companion for 15s so the card can be checked (and moved) without a pet.
BB:RegisterTest("card", function()
    sim = { name = "Rex", happiness = 3, minutes = 250 }
    Update()
    C_Timer.After(15, function()
        sim = nil
        Update()
    end)
    return card:IsShown()
end, true)
