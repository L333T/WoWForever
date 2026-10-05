-- ============================================================================
-- Master Farmer Bot (Ameisen navigation test fork of Master Farmer - Grindbot)
-- Identity — single source of truth for name / authors / version
-- ============================================================================
-- Version: 2.235.3-ameisen
-- Authors: BLIZZ - Anthonyk
-- Folder: Master_Farmer_Bot
-- ============================================================================

-- `folder` is the key for NS._sessions, which is how a freshly loaded
-- instance tells an older one still ticking that it has been superseded.
--
-- It deliberately carries NO version. It used to be folder .. "_v" .. version,
-- which meant the key moved on every release: hot-reloading from one version
-- to the next gave the new instance a different key from the old one, so the
-- old one compared itself against a counter nothing was incrementing, never
-- saw itself superseded, and kept ticking alongside the new load. That is
-- exactly the case the counter exists to catch, and it was the one case it
-- could not catch.
--
-- The on-disk folder can be called whatever you like; nothing reads it.
return {
    name = "Master Farmer Bot",
    short_tag = "MFB",
    description = "Intelligent fully AFK WoW leveling bot",
    authors = "BLIZZ - Anthonyk",
    author = "BLIZZ - Anthonyk",
    version = "2.235.3-ameisen",
    folder = "Master_Farmer_Bot",
}
