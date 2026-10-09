local _, BB = ...
local L = BB.L

local category

local function Build()
    category = Settings.RegisterVerticalLayoutCategory("BeastBond")
    local function AddCheck(key, label, tip)
        local setting = Settings.RegisterAddOnSetting(category, "BB_" .. key, key, BB.db,
            Settings.VarType.Boolean, label, BB.defaults[key])
        Settings.CreateCheckbox(category, setting, tip)
    end
    AddCheck("alertText", L.OPT_ALERT_TEXT, L.OPT_ALERT_TEXT_TIP)
    AddCheck("alertSound", L.OPT_ALERT_SOUND, L.OPT_ALERT_SOUND_TIP)
    AddCheck("feedReminder", L.OPT_FEED, L.OPT_FEED_TIP)
    AddCheck("missingPetAlert", L.OPT_MISSING, L.OPT_MISSING_TIP)
    AddCheck("lockFeedButton", L.OPT_LOCK, L.OPT_LOCK_TIP)
    AddCheck("tameAlert", L.OPT_TAME, L.OPT_TAME_TIP)
    Settings.RegisterAddOnCategory(category)
end

BB:On("PLAYER_LOGIN", Build)

function BB:OpenOptions()
    if category then Settings.OpenToCategory(category:GetID()) end
end
