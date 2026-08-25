-- Autostart

hl.on("hyprland.start", function()
    -- DBus / portal environment (required for xdg-desktop-portal-hyprland)
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Polkit agent
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- Clipboard history and middle-click autoscroll
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("~/.config/hypr/scripts/context-autoscroll.sh")

    hl.exec_cmd("hypridle")
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
    hl.exec_cmd("~/.config/hypr/scripts/wallpaper.sh")
end)
