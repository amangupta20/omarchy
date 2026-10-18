-- Extra autostart processes.
o.launch_on_start("quickshell")

-- Keep the clipboard source alive after the copying app exits, so Omarchy's
-- clipboard history (SUPER + CTRL + V) still has something to capture.
o.launch_on_start("wl-clip-persist --clipboard regular --reconnect-tries inf")
