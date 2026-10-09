local _, BB = ...

-- Missing keys fall back to the key itself, so a translation can be added later without code changes.
local L = setmetatable({}, { __index = function(_, key) return key end })
BB.L = L

L.PET_UNHAPPY = "%s is very unhappy! Feed them before they run away."
L.PET_HUNGRY = "%s is getting hungry."
L.PET_DEAD = "%s has fallen. Cast Revive Pet to bring them back."
L.PET_MISSING = "Your companion is not with you. Cast Call Pet."
L.PET_FALLBACK = "Your pet"

L.BOND = { "New friends", "Buddies", "Good friends", "Inseparable", "Soulbound" }
L.BOND_UP = "%s and you are now %s!"
L.BOND_NEXT = "%s  -  %d min to go"
L.CARD_NO_MOOD = "Your companion"

L.HAPPINESS = { [1] = "Unhappy", [2] = "Content", [3] = "Happy" }
L.TIP_FEEDING = "Feed: %s (%d)"
L.TIP_HAPPINESS = "Pet mood: %s"
L.TIP_DRAG = "Shift+drag to move"

L.JOURNAL_NEW = "New pet in your journal: %s (%s)"
L.TAME_FOUND = "Rare tame nearby: %s (%s, level %d)"
L.OPT_TAME = "Rare tame alert"
L.OPT_TAME_TIP = "Alert when you target or see a rare creature you can tame."
L.OPT_CARD = "Companion card"
L.OPT_CARD_TIP = "Show a small card with your pet: portrait, mood and how close you are."
L.OPT_LOCK = "Lock feed button and card"
L.OPT_LOCK_TIP = "Prevent the feed button and the companion card from being moved."
L.OPT_ALERT_TEXT ="On-screen alerts"
L.OPT_ALERT_TEXT_TIP = "Show raid-warning style text."
L.OPT_ALERT_SOUND = "Alert sound"
L.OPT_ALERT_SOUND_TIP = "Play a sound with alerts."
L.OPT_FEED = "Feed button"
L.OPT_FEED_TIP = "Show a one-click feed button when your pet is hungry."
L.OPT_MISSING = "Missing pet alert"
L.OPT_MISSING_TIP = "Warn when your pet is dead or not summoned."
