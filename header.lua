-- ============================================================================
-- Master Farmer Bot (Ameisen navigation test fork of Master Farmer - Grindbot)
-- Header — load gate
-- ============================================================================
-- Purpose: IZI gate only - loads on every game version. Not class-locked.
-- Authors: BLIZZ - Anthonyk
-- Version: 2.235.3-ameisen
-- Folder: Master_Farmer_Bot
-- ============================================================================

local identity = require("version")

local plugin = {}
plugin["name"] = identity.name
plugin["short_tag"] = identity.short_tag
plugin["version"] = identity.version
plugin["author"] = identity.authors
plugin["load"] = true

-- The header runs before a player exists and is not asked again, so it does
-- not require one. Master Farmer Bot (the Ameisen navigation test fork) loads
-- on EVERY game version: the version is only logged, and posted to the
-- Ameisen HTTP bridge's boot log (127.0.0.1:47110/log) when it is running.
local BOOT_URL = "http://127.0.0.1:47110/log?src=boot"

local function call(fn, ...)
    if type(fn) ~= "function" then return false, "missing" end
    return pcall(fn, ...)
end

local okv, version = call(core.get_game_version)
local line = string.format("Master Farmer Bot %s header: load=true game_version=%s",
    plugin["version"], tostring(okv and version or "unknown"))
call(core.http_post, BOOT_URL, line .. "\n", function() end)
call(core.log, "[Master Farmer Bot] " .. line)

local izi_ok, izi = pcall(require, "common/izi_sdk")
if (not izi_ok) or type(izi) ~= "table" then
    core.log_error("[Master Farmer Bot] common/izi_sdk is unavailable - plugin not loaded.")
    plugin["load"] = false
    return plugin
end

local required_izi = {
    "on_update",
    "spell",
    "item",
    "enemies",
    "me",
    "now",
}
local missing = {}
for i = 1, #required_izi do
    local field = required_izi[i]
    if type(izi[field]) ~= "function" then
        missing[#missing + 1] = field
    end
end
if #missing > 0 then
    core.log_error("[Master Farmer Bot] izi_sdk missing: " .. table.concat(missing, ", "))
    plugin["load"] = false
    return plugin
end

_G.MasterFarmer_Bot = _G.MasterFarmer_Bot or {}
local NS = _G.MasterFarmer_Bot
NS.meta = {
    name = identity.name,
    version = identity.version,
    author = identity.authors,
    description = identity.description,
}
NS._sessions = NS._sessions or {}
NS._sessions[identity.folder] = (NS._sessions[identity.folder] or 0) + 1

return plugin
