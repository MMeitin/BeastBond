local _, BB = ...

-- Missing keys fall back to the key itself, so a translation can be added later without code changes.
local L = setmetatable({}, { __index = function(_, key) return key end })
BB.L = L

L.PET_UNHAPPY = "Your pet is UNHAPPY - feed it now or it will run away!"
L.PET_HUNGRY = "Your pet is getting hungry."
L.PET_DEAD = "Your pet is dead - cast Revive Pet."
L.PET_MISSING = "No pet summoned - cast Call Pet."

L.HAPPINESS = { [1] = "Unhappy", [2] = "Content", [3] = "Happy" }
L.TIP_FEEDING = "Feed: %s (%d)"
L.TIP_HAPPINESS = "Pet mood: %s"
L.TIP_DRAG = "Shift+drag to move"

L.JOURNAL_NEW = "New pet in your journal: %s (%s)"
L.TAME_FOUND = "Rare tame nearby: %s (%s, level %d)"
L.OPT_TAME = "Rare tame alert"
L.OPT_TAME_TIP = "Alert when you target or see a rare creature you can tame."
L.OPT_LOCK = "Lock feed button"
L.OPT_LOCK_TIP = "Prevent the feed button from being moved."
L.OPT_ALERT_TEXT ="On-screen alerts"
L.OPT_ALERT_TEXT_TIP = "Show raid-warning style text."
L.OPT_ALERT_SOUND = "Alert sound"
L.OPT_ALERT_SOUND_TIP = "Play a sound with alerts."
L.OPT_FEED = "Feed button"
L.OPT_FEED_TIP = "Show a one-click feed button when your pet is hungry."
L.OPT_MISSING = "Missing pet alert"
L.OPT_MISSING_TIP = "Warn when your pet is dead or not summoned."
