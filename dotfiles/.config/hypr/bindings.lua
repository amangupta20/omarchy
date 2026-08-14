-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Unbind default SUPER + W (which was close window in Quattro)
hl.unbind("SUPER + W")

-- Close active window with SUPER + Q
o.bind("SUPER + Q", "Close active window", hl.dsp.window.close())

-- Workspace manager overview on SUPER + A (Quickshell)
o.bind("SUPER + A", "Workspace overview", hl.dsp.global("quickshell:overviewToggle"))

-- Wallpaper selector on SUPER + W
o.bind("SUPER + W", "Wallpaper selector", "omarchy-theme-bg-switcher")

-- Applications
-- File manager on SUPER + F, Fullscreen on SUPER + SHIFT + F
hl.unbind("SUPER + F")
o.bind("SUPER + F", "File manager", "uwsm app -- nautilus --new-window")
o.bind("SUPER + SHIFT + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

-- Browser (Zen Browser)
hl.unbind("SUPER + SHIFT + B")
o.bind("SUPER + B", "Browser", "uwsm app -- zen-browser")
o.bind("SUPER + SHIFT + B", "Browser (private)", "uwsm app -- zen-browser --private-window")

o.bind("SUPER + M", "Music", "omarchy-launch-or-focus spotify")
o.bind("SUPER + N", "Editor", "omarchy-launch-editor")
o.bind("SUPER + T", "Activity", { tui = "btop" })
o.bind("SUPER + D", "Docker", { tui = "lazydocker" })
o.bind("SUPER + G", "Signal", "omarchy-launch-or-focus signal 'uwsm app -- signal-desktop'")
o.bind("SUPER + O", "Obsidian", "omarchy-launch-or-focus obsidian 'uwsm app -- obsidian'")
o.bind("SUPER + slash", "Passwords", "uwsm app -- 1password")

-- Web apps
hl.unbind("SUPER + SHIFT + A")
hl.unbind("SUPER + SHIFT + G")
hl.unbind("SUPER + SHIFT + X")

o.bind("SUPER + Y", "YouTube", { webapp = "https://youtube.com/", focus = true })
o.bind("SUPER + SHIFT + G", "WhatsApp", { webapp = "https://web.whatsapp.com/", focus = true })
o.bind("SUPER + ALT + G", "Google Messages", { webapp = "https://messages.google.com/web/conversations", focus = true })
o.bind("SUPER + SHIFT + A", "Grok", { webapp = "https://grok.com" })
o.bind("SUPER + C", "Calendar", { webapp = "https://app.hey.com/calendar/weeks/" })
o.bind("SUPER + E", "Email", { webapp = "https://app.hey.com" })
o.bind("SUPER + X", "X", { webapp = "https://x.com/" })
o.bind("SUPER + SHIFT + X", "X Post", { webapp = "https://x.com/compose/post" })

