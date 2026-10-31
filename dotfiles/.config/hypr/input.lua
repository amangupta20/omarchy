-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults.

-- Keyboard layout and options.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input
hl.config({
  input = {
    repeat_delay = 600,
    touchpad = {
      natural_scroll = true,
      scroll_factor = 0.4,
    },
  },
})

hl.device({
  name = "instant-usb-gaming-mouse-",
  sensitivity = -0.35,
})

-- App-specific touchpad scroll speeds.
-- o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
-- o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- Change one of Omarchy's touchpad gestures by unsetting it first, since
-- Hyprland rejects a second gesture on the same fingers and direction. This
-- makes a three-finger swipe move focus instead (helpful on scrolling layout).
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
-- hl.gesture({ fingers = 3, direction = "left", action = "unset" })
-- hl.gesture({ fingers = 3, direction = "right", action = "unset" })
-- hl.gesture({ fingers = 3, direction = "left", action = function() hl.dispatch(hl.dsp.focus({ direction = "l" })) end })
-- hl.gesture({ fingers = 3, direction = "right", action = function() hl.dispatch(hl.dsp.focus({ direction = "r" })) end })
