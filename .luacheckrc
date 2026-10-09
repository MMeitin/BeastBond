std = "lua51"
max_line_length = false
codes = true
exclude_files = { ".release/" }

-- unused self / underscore args in handlers are fine
ignore = { "212/self", "212/_.*" }

globals = {
    "BeastBondDB",
    "BeastBond",
    "SLASH_BEASTBOND1", "SLASH_BEASTBOND2",
    "SlashCmdList",
}

read_globals = {
    -- frames / API
    "CreateFrame", "UIParent", "C_Timer", "C_PetInfo", "C_StableInfo", "C_Container", "C_Item", "C_AddOns",
    "GetAddOnMetadata", "GetBuildInfo", "geterrorhandler", "CopyTable", "strjoin", "tostringall",
    "UnitExists", "UnitIsDead", "UnitIsDeadOrGhost", "UnitOnTaxi", "IsMounted", "UnitClass", "UnitLevel", "UnitGUID",
    "GetTime", "time", "wipe", "SetPortraitTexture", "GetRealmName", "GetRealZoneText", "date", "UISpecialFrames", "ChatFontNormal", "strsplit", "IsInInstance", "UnitName", "UnitIsPlayer", "UnitClassification", "UnitCreatureFamily",
    "InCombatLockdown", "IsShiftKeyDown", "PlaySound", "SOUNDKIT",
    "RaidNotice_AddMessage", "RaidWarningFrame", "ChatTypeInfo",
    "NUM_BAG_SLOTS", "Settings", "ChatFrame1", "GameTooltip",
}
