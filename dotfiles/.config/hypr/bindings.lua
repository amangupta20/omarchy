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

-- Free the keys Omarchy binds by default that this file replaces.
hl.unbind("SUPER + W")          -- close window -> wallpaper selector
hl.unbind("SUPER + SHIFT + W")  -- Omawrite -> wallpaper effects
hl.unbind("SUPER + F")          -- full screen -> file manager
hl.unbind("SUPER + SHIFT + F")  -- file manager -> full screen
hl.unbind("SUPER + SHIFT + B")  -- browser -> private browser
hl.unbind("SUPER + C")          -- universal copy -> unused (Ctrl+C is used)
hl.unbind("SUPER + X")          -- universal cut -> unused (Ctrl+X is used)
hl.unbind("SUPER + Q")          -- default close -> the single bind below
hl.unbind("SUPER + A")          -- select all (newer Omarchy) -> overview below

-- Close active window with SUPER + Q
o.bind("SUPER + Q", "Close active window", hl.dsp.window.close())

-- Workspace manager overview on SUPER + A (Quickshell)
o.bind("SUPER + A", "Workspace overview", hl.dsp.global("quickshell:overviewToggle"))

-- Wallpaper selector on SUPER + W & effects on SUPER + SHIFT + W
o.bind("SUPER + W", "Wallpaper selector", os.getenv("HOME") .. "/.config/hypr/UserScripts/WallpaperSelect.sh")
o.bind("SUPER + SHIFT + W", "Wallpaper effects", os.getenv("HOME") .. "/.config/hypr/UserScripts/WallpaperEffects.sh")

-- Applications
-- File manager on SUPER + F, Fullscreen on SUPER + SHIFT + F
o.bind("SUPER + F", "File manager", "uwsm app -- nautilus --new-window")
o.bind("SUPER + SHIFT + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

-- Browser (Zen is the xdg default; omarchy-launch-browser follows it)
o.bind("SUPER + B", "Browser", { omarchy = "browser" })
o.bind("SUPER + SHIFT + B", "Browser (private)", { omarchy = "browser --private" })

-- The preinstalled app launchers are Omarchy's defaults:
--   SUPER + SHIFT + M        music (Spotify)
--   SUPER + SHIFT + G        Signal
--   SUPER + SHIFT + O        Obsidian
--   SUPER + SHIFT + SLASH    passwords (1Password)
--   SUPER + SHIFT + ALT + G  WhatsApp (once Omarchy's next update lands)
o.bind("SUPER + N", "Editor", "omarchy-launch-editor")
o.bind("SUPER + D", "Docker", { tui = "lazydocker" })

-- Web apps
hl.unbind("SUPER + SHIFT + A")
hl.unbind("SUPER + SHIFT + X")
-- Upstream binds this to "Move active window out of group"; free it first or
-- both actions fire. Upstream's own Google Messages binding is SUPER + SHIFT + CTRL + G.
hl.unbind("SUPER + ALT + G")

o.bind("SUPER + SHIFT + A", "Grok", { webapp = "https://grok.com" })
o.bind("SUPER + E", "Email", { webapp = "https://app.hey.com" })
o.bind("SUPER + Y", "YouTube", { webapp = "https://youtube.com/", focus = true })
o.bind("SUPER + ALT + G", "Google Messages", { webapp = "https://messages.google.com/web/conversations", focus = true })
o.bind("SUPER + SHIFT + X", "X Post", { webapp = "https://x.com/compose/post" })
