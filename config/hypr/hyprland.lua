-- Cyrodiil - Hyprland config

require("env")
require("monitors")
require("input")
require("appearance")

local function loadOptionalModule(name)
    local loaded, loadError = pcall(require, name)
    if not loaded and not loadError:match("module '" .. name .. "' not found") then
        error(loadError)
    end
end

-- install.sh manages options.lua. local.lua is reserved for user overrides.
cyrodiil_options = {}
if os.getenv("CYRODIIL_SKIP_OPTIONS") ~= "1" then
    loadOptionalModule("options")
end
loadOptionalModule("local")

require("autostart")
require("keybinds")
require("rules")
