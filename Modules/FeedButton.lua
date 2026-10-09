local _, BB = ...
local L = BB.L
local mod = BB:NewModule("FeedButton")

local DEFAULT_POINT = { "CENTER", "CENTER", 0, -150 }

-- `sim` fakes food/happiness for /bb test feed (cleared automatically)
local sim

-- Secure one-click feed button. Out of combat only (secure attributes can't change in combat).
local btn = CreateFrame("Button", "BeastBondFeedButton", UIParent, "SecureActionButtonTemplate")
btn:SetSize(44, 44)
btn:SetFrameStrata("DIALOG")
btn:SetPoint(DEFAULT_POINT[1], UIParent, DEFAULT_POINT[2], DEFAULT_POINT[3], DEFAULT_POINT[4])
btn:RegisterForClicks("AnyUp", "AnyDown")
btn:Hide()

-- Same art the default action bar buttons use, so it blends into the Forever UI
btn.icon = btn:CreateTexture(nil, "BACKGROUND")
btn.icon:SetAllPoints()
btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
btn:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
local normal = btn:GetNormalTexture()
normal:ClearAllPoints()
normal:SetPoint("TOPLEFT", -15, 15) -- the frame art is ~1.8x the icon, like ActionButtonTemplate
normal:SetPoint("BOTTOMRIGHT", 15, -15)
btn:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
btn.count = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
btn.count:SetPoint("BOTTOMRIGHT", -3, 3)
btn:SetAttribute("type", "macro")

-- Shift+drag to move (unless locked); position saved in BeastBondDB.pos
btn:SetMovable(true)
btn:SetClampedToScreen(true)
btn:RegisterForDrag("LeftButton")
btn:SetScript("OnDragStart", function(self)
    if IsShiftKeyDown() and not BB.db.lockFeedButton and not InCombatLockdown() then self:StartMoving() end
end)
btn:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, rel, x, y = self:GetPoint()
    BB.db.pos = { point, rel, x, y }
end)

local function CurrentHappiness()
    if sim and sim.happiness then return sim.happiness end
    return BB:GetHappiness()
end

btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine("BeastBond")
    if self.foodName then
        GameTooltip:AddLine(L.TIP_FEEDING:format(self.foodName, self.foodCount or 0), 1, 1, 1)
    end
    local mood = L.HAPPINESS[CurrentHappiness()]
    if mood then GameTooltip:AddLine(L.TIP_HAPPINESS:format(mood), 1, 1, 1) end
    if not BB.db.lockFeedButton then GameTooltip:AddLine(L.TIP_DRAG, 0.6, 0.6, 0.6) end
    GameTooltip:Show()
end)
btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

local function ApplyPosition()
    local p = BB.db.pos or DEFAULT_POINT
    btn:ClearAllPoints()
    btn:SetPoint(p[1], UIParent, p[2], p[3], p[4])
end

-- Scan bags for the first item the pet can eat (C_PetInfo.CanPetEatItem).
local function FindFood()
    if sim and sim.food then return sim.food.itemID, sim.food.icon, sim.food.name, sim.food.count end
    if not (C_PetInfo and C_PetInfo.CanPetEatItem) then return end
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID and C_PetInfo.CanPetEatItem(info.itemID) then
                local count = (C_Item.GetItemCount and C_Item.GetItemCount(info.itemID)) or info.stackCount or 1
                return info.itemID, info.iconFileID, info.itemName or C_Item.GetItemNameByID(info.itemID), count
            end
        end
    end
end

local function Refresh()
    if InCombatLockdown() then return end
    local _, class = UnitClass("player")
    local active = sim or (class == "HUNTER" and UnitExists("pet"))
    if not active or not BB.db.feedReminder then btn:Hide() return end
    local h = CurrentHappiness()
    if type(h) == "number" and h >= 3 then btn:Hide() return end -- only show when not happy
    local itemID, texture, name, count = FindFood()
    if itemID then
        btn.foodName, btn.foodCount = name, count
        btn:SetAttribute("macrotext", "/cast Feed Pet\n/use " .. name)
        btn.icon:SetTexture(texture)
        btn.count:SetText((count or 0) > 1 and count or "")
        btn:SetAlpha(1)
        btn:Show()
    else
        btn:Hide()
    end
end

function mod:OnEnable()
    ApplyPosition()
end

function mod:OnDisable()
    if not InCombatLockdown() then btn:Hide() end
end

mod:On("BAG_UPDATE_DELAYED", Refresh)
mod:On("UNIT_HAPPINESS", Refresh)
mod:On("PLAYER_REGEN_ENABLED", Refresh)
mod:On("UNIT_PET", Refresh)
-- Hiding a secure button is blocked once combat starts; fade it instead (Feed Pet can't be used in combat anyway)
mod:On("PLAYER_REGEN_DISABLED", function() btn:SetAlpha(0) end)

BB:RegisterCommand("reset", function(self)
    if InCombatLockdown() then self:Print("can't reset in combat") return end
    self.db.pos = nil
    ApplyPosition()
    self:Print("feed button position reset")
end, "reset the feed button position")

-- Shows the button with fake food for 15s so look, tooltip and dragging can be checked without a pet.
BB:RegisterTest("feed", function()
    if InCombatLockdown() then return false end
    sim = { happiness = 2, food = { itemID = 0, icon = 133972, name = "Test Food", count = 5 } }
    Refresh()
    C_Timer.After(15, function()
        sim = nil
        Refresh()
    end)
    return btn:IsShown()
end, true)
