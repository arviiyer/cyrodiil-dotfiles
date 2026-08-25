-- Environment variables

-- XDG
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Toolkit backends
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("CLUTTER_BACKEND", "wayland")

-- Firefox
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- Electron / Chromium apps
hl.env("OZONE_PLATFORM", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

-- Cursor
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic-Gruvbox")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic-Gruvbox")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})

-- HiDPI is handled by the monitor scale in monitors.lua.
hl.env("GDK_SCALE", "1")
