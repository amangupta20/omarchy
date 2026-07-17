#!/bin/bash

set -eEo pipefail

PERSONAL_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
OMARCHY_PATH=$(cd -- "$PERSONAL_DIR/.." && pwd)
TEST_HOME=$(mktemp -d)
FAIL_HOME=$(mktemp -d)

cleanup() {
  rm -rf "$TEST_HOME"
  rm -rf "$FAIL_HOME"
}
trap cleanup EXIT

mkdir -p "$TEST_HOME/.config/hypr"
mkdir -p "$TEST_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
mkdir -p "$TEST_HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
touch "$TEST_HOME/.oh-my-zsh/oh-my-zsh.sh"
touch "$TEST_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"
touch "$TEST_HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh"
printf 'pre-existing bash config\n' >"$TEST_HOME/.bashrc"
printf 'pre-existing monitor config\n' >"$TEST_HOME/.config/hypr/monitors.conf"
ln -s "$OMARCHY_PATH/dotfiles/.config/hypr/autostart.conf" "$TEST_HOME/.config/autostart.conf"
ln -s "$(realpath --relative-to="$TEST_HOME/.config" "$OMARCHY_PATH/dotfiles/.config/nvim")" "$TEST_HOME/.config/nvim"

HOME="$TEST_HOME" "$PERSONAL_DIR/recover.sh" --link -y >/dev/null

[[ -d $TEST_HOME/.config && ! -L $TEST_HOME/.config ]]
[[ -L $TEST_HOME/.bashrc ]]
[[ -L $TEST_HOME/.zshrc ]]
[[ -L $TEST_HOME/.config/hypr/hyprland.conf ]]
[[ -L $TEST_HOME/.config/hypr/monitors.conf ]]
[[ -L $TEST_HOME/.config/waybar/style.css ]]
[[ -L $TEST_HOME/.config/waybar/config ]]
[[ -L $TEST_HOME/.config/rofi/.current_wallpaper ]]
[[ ! -e $TEST_HOME/.config/autostart.conf && ! -L $TEST_HOME/.config/autostart.conf ]]
[[ $(readlink -f "$TEST_HOME/.config/waybar/config") == "$OMARCHY_PATH/dotfiles/.config/waybar/configs/[BOT] Main" ]]
[[ $(readlink "$TEST_HOME/.config/rofi/.current_wallpaper") == "$TEST_HOME/.config/omarchy/current/background" ]]

backup_root=$(find "$TEST_HOME/.local/state/omarchy/personal-backups" -mindepth 1 -maxdepth 1 -type d -print -quit)
[[ -n $backup_root ]]
grep -q "pre-existing bash config" "$backup_root/.bashrc"
grep -q "pre-existing monitor config" "$backup_root/.config/hypr/monitors.conf"
[[ ! -e $backup_root/.config/nvim ]]
[[ -f $OMARCHY_PATH/dotfiles/.config/nvim/init.lua ]]

HOME="$TEST_HOME" "$PERSONAL_DIR/recover.sh" --check >/dev/null

backup_count_before=$(find "$TEST_HOME/.local/state/omarchy/personal-backups" -mindepth 1 -maxdepth 1 -type d | wc -l)
HOME="$TEST_HOME" "$PERSONAL_DIR/recover.sh" --link -y >/dev/null
backup_count_after=$(find "$TEST_HOME/.local/state/omarchy/personal-backups" -mindepth 1 -maxdepth 1 -type d | wc -l)
((backup_count_before == backup_count_after))
HOME="$TEST_HOME" "$PERSONAL_DIR/recover.sh" --check >/dev/null

mkdir -p "$FAIL_HOME/bin"
printf '#!/bin/bash\nexit 1\n' >"$FAIL_HOME/bin/stow"
chmod 0755 "$FAIL_HOME/bin/stow"
printf 'must survive failed recovery\n' >"$FAIL_HOME/.bashrc"

if HOME="$FAIL_HOME" PATH="$FAIL_HOME/bin:$PATH" "$PERSONAL_DIR/recover.sh" --link -y >/dev/null 2>&1; then
  echo "Forced Stow failure unexpectedly succeeded" >&2
  exit 1
fi

grep -q "must survive failed recovery" "$FAIL_HOME/.bashrc"

echo "Recovery test passed"
