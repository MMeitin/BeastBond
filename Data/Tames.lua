local _, BB = ...

-- Optional enrichment for the rare tame tracker, keyed by creature ID (the 6th field of a creature GUID).
-- The tracker works without any entries: it alerts on any rare creature that has a pet family.
-- An entry only adds extra detail to the alert. Only add verified entries from the Forever client.
--
-- [creatureID] = { zone = "Mulgore", skin = "Unique coat", note = "short tip" },
BB.Tames = {}
