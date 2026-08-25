-- Cyrodiil - Hyprland config

require("env")
require("monitors")
require("input")
require("appearance")
require("autostart")
require("keybinds")
require("rules")

-- install.sh creates this ignored file for hardware-specific overrides.
local loaded, loadError = pcall(require, "local")
if not loaded and not loadError:match("module 'local' not found") then
    error(loadError)
end
