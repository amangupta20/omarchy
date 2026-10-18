#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
# Wallpaper effects using ImageMagick, applied through Omarchy's background
# engine so the shell and lock screen see the result (SUPER + SHIFT + W).

wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
wallpaper_output="$HOME/.config/hypr/wallpaper_effects/.wallpaper_modified"
rofi_theme="$HOME/.config/rofi/config-wallpaper-effect.rasi"
iDIR="$HOME/.config/swaync/images"
current_background="$HOME/.local/state/omarchy/current/background"

current_path=$(readlink -f "$current_background" 2>/dev/null)
if [[ -z $current_path || ! -f $current_path ]]; then
  notify-send -i "$iDIR/error.png" "No wallpaper" "No current background to modify"
  exit 1
fi

if [[ ${current_path,,} =~ \.(mp4|m4v|mov|webm|mkv|avi)$ ]]; then
  notify-send -i "$iDIR/error.png" "Video wallpaper" "Effects are only available for images"
  exit 1
fi

# Keep the unmodified image so "No Effects" can put it back. When the current
# background is already our own copy, the original is still on disk.
if [[ $current_path != "$wallpaper_output" && $current_path != "$wallpaper_current" ]]; then
  cp -f "$current_path" "$wallpaper_current"
fi

# ImageMagick filters; the source is $wallpaper_current and the result is
# written to $wallpaper_output as PNG.
declare -A effects=(
  ["Black & White"]="-colorspace gray -sigmoidal-contrast 10,40%"
  ["Blurred"]="-blur 0x10"
  ["Charcoal"]="-charcoal 0x5"
  ["Edge Detect"]="-edge 1"
  ["Emboss"]="-emboss 0x5"
  ["Frame Raised"]="+raise 150"
  ["Frame Sunk"]="-raise 150"
  ["Negate"]="-negate"
  ["Oil Paint"]="-paint 4"
  ["Posterize"]="-posterize 4"
  ["Polaroid"]="-polaroid 0"
  ["Sepia Tone"]="-sepia-tone 65%"
  ["Solarize"]="-solarize 80%"
  ["Sharpen"]="-sharpen 0x5"
  ["Vignette"]="-vignette 0x3"
  ["Vignette-black"]="-background black -vignette 0x3"
  ["Zoomed"]="-gravity Center -extent 1:1"
)

apply_effect() {
  local filter="$1"
  local -a args
  read -r -a args <<<"$filter"
  magick "$wallpaper_current" "${args[@]}" "png:$wallpaper_output" || return 1
  omarchy-theme-bg-set "$wallpaper_output"
}

no-effects() {
  omarchy-theme-bg-set "$wallpaper_current"
  notify-send -u low -i "$iDIR/ja.png" "No effects" "original wallpaper restored"
}

main() {
  local options=("No Effects")
  local effect choice

  for effect in "${!effects[@]}"; do
    options+=("$effect")
  done

  choice=$(printf "%s\n" "${options[@]}" | LC_COLLATE=C sort | rofi -dmenu -i -config "$rofi_theme")
  [[ -z $choice ]] && exit 0

  if [[ $choice == "No Effects" ]]; then
    no-effects
    return
  fi

  if [[ -z ${effects[$choice]+exists} ]]; then
    echo "Effect '$choice' not recognized."
    exit 1
  fi

  notify-send -u normal -i "$iDIR/ja.png" "Applying:" "$choice effects"
  if apply_effect "${effects[$choice]}"; then
    notify-send -u low -i "$iDIR/ja.png" "$choice" "effects applied"
  else
    notify-send -u critical -i "$iDIR/error.png" "Wallpaper effect failed" "$choice"
  fi
}

if pidof rofi >/dev/null; then
  pkill rofi
fi

main
