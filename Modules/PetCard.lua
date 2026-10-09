local _, BB = ...
local L = BB.L
local mod = BB:NewModule("PetCard")

local DEFAULT_POINT = { "CENTER", "CENTER", -320, -180 }
local MEDIA = "Interface\\AddOns\\BeastBond\\Media\\"

-- Same mood faces the default pet UI uses (one texture strip: happy | content | unhappy)
local FACE_TEXTURE = "Interface\\PetPaperDollFrame\\UI-PetHappiness"
local FACE_COORDS = { [1] = { 0.375, 0.5625 }, [2] = { 0.1875, 0.375 }, [3] = { 0, 0.1875 } }
local MOOD_COLORS = { [1] = "|cffe64035", [2] = "|cffffd100", [3] = "|cff59d959" }
local BAR_GREEN = { 0.45, 0.8, 0.35 }
local BAR_GOLD = { 1, 0.82, 0.2 } -- Soulbound

-- `sim` fakes a pet for /bb test card (cleared automatically)
local sim

-- Leather and gold card: 256x84 on the top of a 256x128 texture sheet
local card = CreateFrame("Frame", "BeastBondCard", UIParent)
card:SetSize(256, 84)
card:SetFrameStrata("MEDIUM")
card:Hide()

card.bg = card:CreateTexture(nil, "BACKGROUND")
card.bg:SetAllPoints()
card.bg:SetTexture(MEDIA .. "card.tga")
card.bg:SetTexCoord(0, 1, 0, 84 / 128)

-- Portrait sits inside a gold ring
card.portrait = card:CreateTexture(nil, "ARTWORK")
card.portrait:SetSize(48, 48)
card.portrait:SetPoint("LEFT", 18, 0)
card.ring = card:CreateTexture(nil, "OVERLAY")
card.ring:SetSize(64, 64)
card.ring:SetPoint("CENTER", card.portrait, "CENTER")
card.ring:SetTexture(MEDIA .. "ring.tga")

card.name = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
card.name:SetPoint("TOPLEFT", 88, -11)

card.face = card:CreateTexture(nil, "ARTWORK")
card.face:SetSize(16, 16)
card.face:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -3)
card.face:SetTexture(FACE_TEXTURE)

card.mood = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
card.mood:SetPoint("LEFT", card.face, "RIGHT", 5, 0)

-- Bond bar: dark backing, tinted glossy fill, gold groove on top, text inside
card.bar = CreateFrame("StatusBar", nil, card)
card.bar:SetSize(150, 14)
card.bar:SetPoint("BOTTOMLEFT", 88, 14)
card.bar:SetStatusBarTexture(MEDIA .. "barfill.tga")
card.bar:SetMinMaxValues(0, 1)
card.bar.back = card.bar:CreateTexture(nil, "BACKGROUND")
card.bar.back:SetAllPoints()
card.bar.back:SetTexture(MEDIA .. "barback.tga")
card.bar.groove = card.bar:CreateTexture(nil, "OVERLAY", nil, 1)
card.bar.groove:SetPoint("TOPLEFT", -6, 5)
card.bar.groove:SetPoint("BOTTOMRIGHT", 6, -5)
card.bar.groove:SetTexture(MEDIA .. "barframe.tga")
card.bar.rank = card.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
card.bar.rank:SetPoint("LEFT", 6, 0)
card.bar.rank:SetDrawLayer("OVERLAY", 3)
card.bar.left = card.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
card.bar.left:SetPoint("RIGHT", -6, 0)
card.bar.left:SetDrawLayer("OVERLAY", 3)

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

card:SetScript("OnEnter", function(self)
    local entry = BB:CurrentPetEntry()
    local name = UnitName("pet")
    local days, cared, zones
    if sim then
        name, days, cared, zones = sim.name, 12, 3, 6
    elseif entry then
        days, cared, zones = BB:PetStats(entry)
    end
    if not days then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(name or L.CARD_NO_MOOD)
    GameTooltip:AddLine(("Together for %d %s"):format(days, days == 1 and "day" or "days"), 1, 1, 1)
    GameTooltip:AddLine(("Nursed back to health: %d"):format(cared), 1, 1, 1)
    GameTooltip:AddLine(("Zones explored: %d"):format(zones), 1, 1, 1)
    GameTooltip:AddLine(L.TIP_STORY, 0.6, 0.6, 0.6)
    GameTooltip:Show()
end)
card:SetScript("OnLeave", function() GameTooltip:Hide() end)

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
    local active = sim or (class == "HUNTER" and UnitExists("pet"))
    if not (BB.db.showCard and active) then card:Hide() return end

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

    local level, bondName, progress, nextAt = BB:BondLevel(minutes)
    local tint = level == #BB.BOND_STEPS and BAR_GOLD or BAR_GREEN
    card.bar:SetStatusBarColor(tint[1], tint[2], tint[3])
    card.bar:SetValue(progress)
    card.bar.rank:SetText(bondName)
    card.bar.left:SetText(nextAt and ((nextAt - minutes) .. " min") or "")
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
