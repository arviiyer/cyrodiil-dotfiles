-- Appearance
-- Palette: warm grays, terracotta, muted orange, sand, olive

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(c4845aff)", "rgba(644e3aff)" }, angle = 45 },
            inactive_border = "rgba(221a12ff)",
        },
        layout = "dwindle",
        resize_on_border = true,
    },

    decoration = {
        rounding = 10,
        blur = {
            enabled = true,
            size = 6,
            passes = 3,
            new_optimizations = true,
            xray = false,
        },
        shadow = {
            enabled = true,
            range = 12,
            render_power = 3,
            color = "rgba(0d0a0855)",
        },
        active_opacity = 0.92,
        inactive_opacity = 0.90,
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        focus_on_activate = false,
        render_unfocused_fps = 30, -- Save GPU time for active tasks.
    },

    render = {
        -- Direct scanout causes blank screens with some games on NVIDIA.
        direct_scanout = false,
    },
})

hl.curve("ease", { type = "bezier", points = { { 0.25, 0.1 }, { 0.25, 1.0 } } })
hl.curve("easeOut", { type = "bezier", points = { { 0.0, 0.0 }, { 0.2, 1.0 } } })
hl.curve("easeIn", { type = "bezier", points = { { 0.4, 0.0 }, { 1.0, 1.0 } } })
hl.curve("linear", { type = "bezier", points = { { 0.0, 0.0 }, { 1.0, 1.0 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 1.5, bezier = "easeOut", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.5, bezier = "easeIn", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 1.5, bezier = "ease" })
hl.animation({ leaf = "fade", enabled = true, speed = 1.5, bezier = "ease" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.5, bezier = "easeIn" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.5, bezier = "easeOut", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "linear" })
