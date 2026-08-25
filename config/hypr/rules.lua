-- Window rules

hl.window_rule({
    name = "workspace-ghostty",
    match = { class = [[^(com\.mitchellh\.ghostty)$]] },
    workspace = "1",
})

hl.window_rule({
    name = "workspace-firefox",
    match = { class = "^(firefox)$" },
    workspace = "2",
})

hl.window_rule({
    name = "workspace-nautilus",
    match = { class = [[^(org\.gnome\.Nautilus)$]] },
    workspace = "3",
})

hl.window_rule({
    name = "workspace-steam",
    match = { class = "^(steam)$" },
    workspace = "4",
})

hl.window_rule({
    name = "workspace-discord",
    match = { class = "^(discord)$" },
    workspace = "5",
})

hl.window_rule({
    name = "pavucontrol",
    match = { class = "^(pavucontrol)$" },
    float = true,
    center = true,
    size = { 700, 500 },
})

hl.window_rule({
    name = "blueman",
    match = { class = "^(blueman-manager)$" },
    float = true,
    center = true,
})

hl.window_rule({
    name = "nm-connection-editor",
    match = { class = "^(nm-connection-editor)$" },
    float = true,
    center = true,
})

hl.window_rule({
    name = "nwg-look",
    match = { class = "^(nwg-look)$" },
    float = true,
    center = true,
})

hl.window_rule({
    name = "nwg-displays",
    match = { class = "^(nwg-displays)$" },
    float = true,
    center = true,
})

hl.window_rule({
    name = "pip",
    match = { title = [[^([Pp]icture[-\s]?[Ii]n[-\s]?[Pp]icture)(.*)$]] },
    float = true,
    pin = true,
})

hl.window_rule({
    name = "xdg-file-picker",
    match = { class = "^(xdg-desktop-portal-gtk)$" },
    float = true,
    center = true,
})

hl.window_rule({
    name = "hyprland-share-picker",
    match = { class = "^(hyprland-share-picker)$" },
    float = true,
    center = true,
    size = { 600, 400 },
})

hl.window_rule({
    name = "system-update",
    match = { title = "^system-update$" },
    float = true,
    center = true,
    size = { 900, 600 },
})

hl.window_rule({
    name = "gsimplecal",
    match = { class = "^(gsimplecal)$" },
    float = true,
    opacity = "0.92 0.92",
})

hl.window_rule({
    name = "rofi",
    match = { class = "^(Rofi)$" },
    opacity = "0.92 0.92",
})

-- Example layer rules:
-- hl.layer_rule({ match = { namespace = "waybar" }, blur = true })
-- hl.layer_rule({ match = { namespace = "waybar" }, ignore_alpha = 0 })
