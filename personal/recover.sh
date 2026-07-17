#!/bin/bash

set -eEo pipefail

PERSONAL_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
OMARCHY_PATH=$(cd -- "$PERSONAL_DIR/.." && pwd)
DOTFILES_DIR="$OMARCHY_PATH/dotfiles"
PACKAGE_FILE="$PERSONAL_DIR/packages.txt"
MODE="check"
ASSUME_YES=false

usage() {
  cat <<'EOF'
Usage: personal/recover.sh [--check|--link|--apply] [-y]

  --check  Inspect prerequisites and portability without changing the system.
  --link   Back up collisions and link the personal dotfiles with GNU Stow.
  --apply  Install personal packages, then perform --link.
  -y       Skip the confirmation required by --link and --apply.

Run this after installing Omarchy from this fork. See RECOVERY.md for the full
fresh-machine procedure and the hardware-specific checks to perform afterward.
EOF
}

while (($# > 0)); do
  case "$1" in
    --check | --link | --apply)
      MODE=${1#--}
      ;;
    -y | --yes)
      ASSUME_YES=true
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

status=0
ACTIVE_BACKUP_ROOT=""
LEGACY_HYPR_LINKS=(
  autostart.conf
  bindings.conf
  envs.conf
  hypridle.conf
  hyprland.conf
  hyprlock.conf
  hyprsunset.conf
  input.conf
  looknfeel.conf
  monitors.conf
  workspaces.conf
)

rollback_recovery() {
  local exit_code=$? backup_path relative_path target_path

  trap - ERR

  if [[ -n $ACTIVE_BACKUP_ROOT && -d $ACTIVE_BACKUP_ROOT ]]; then
    echo "Recovery failed; restoring files from $ACTIVE_BACKUP_ROOT" >&2

    while IFS= read -r -d '' backup_path; do
      relative_path=${backup_path#"$ACTIVE_BACKUP_ROOT"/}
      target_path="$HOME/$relative_path"
      mkdir -p "$(dirname -- "$target_path")"
      rm -f -- "$target_path"
      mv -- "$backup_path" "$target_path"
    done < <(find "$ACTIVE_BACKUP_ROOT" \( -type f -o -type l \) -print0)
  fi

  exit "$exit_code"
}
trap rollback_recovery ERR

report_command() {
  local command_name=$1

  if command -v "$command_name" >/dev/null 2>&1; then
    printf 'ok      command: %s\n' "$command_name"
  else
    printf 'missing command: %s\n' "$command_name"
    status=1
  fi
}

report_link() {
  local path=$1
  local expected=$2

  if [[ -e $path && $(readlink -f "$path") == $(readlink -f "$expected") ]]; then
    printf 'ok      linked:  %s\n' "$path"
  elif [[ -e $path || -L $path ]]; then
    printf 'local   target:  %s\n' "$path"
    status=1
  else
    printf 'missing target:  %s\n' "$path"
    status=1
  fi
}

check_repository() {
  echo "Repository: $OMARCHY_PATH"

  if ! git -C "$OMARCHY_PATH" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "error: $OMARCHY_PATH is not a Git checkout" >&2
    status=1
  fi

  if [[ ! -d $DOTFILES_DIR || ! -f $PACKAGE_FILE ]]; then
    echo "error: personal recovery files are incomplete" >&2
    status=1
  fi

  report_command git
  report_command stow

  if [[ -f $HOME/.oh-my-zsh/oh-my-zsh.sh && -f $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh && -f $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh ]]; then
    echo "ok      shell:    Oh My Zsh and personal plugins"
  else
    echo "missing shell:    run --apply to install Oh My Zsh and personal plugins"
    status=1
  fi

  report_link "$HOME/.bashrc" "$DOTFILES_DIR/.bashrc"
  report_link "$HOME/.zshrc" "$DOTFILES_DIR/.zshrc"
  report_link "$HOME/.config/hypr/hyprland.conf" "$DOTFILES_DIR/.config/hypr/hyprland.conf"
  report_link "$HOME/.config/waybar/style.css" "$DOTFILES_DIR/.config/waybar/style.css"

  for legacy_name in "${LEGACY_HYPR_LINKS[@]}"; do
    if [[ -L $HOME/.config/$legacy_name && $(readlink -f "$HOME/.config/$legacy_name" 2>/dev/null || true) == "$DOTFILES_DIR/.config/hypr/$legacy_name" ]]; then
      printf 'legacy  linked:  %s\n' "$HOME/.config/$legacy_name"
      status=1
    fi
  done

  if [[ -n $(git -C "$OMARCHY_PATH" status --short) ]]; then
    echo "warning: the repository has uncommitted changes"
  fi

  if git -C "$OMARCHY_PATH" remote get-url origin >/dev/null 2>&1; then
    printf 'origin:  %s\n' "$(git -C "$OMARCHY_PATH" remote get-url origin)"
  else
    echo "warning: the checkout has no origin remote"
  fi
}

install_packages() {
  local -a packages=()

  while IFS= read -r package; do
    [[ -z $package || $package == \#* ]] && continue
    packages+=("$package")
  done <"$PACKAGE_FILE"

  if command -v omarchy-pkg-add >/dev/null 2>&1; then
    omarchy-pkg-add "${packages[@]}"
  else
    echo "error: omarchy-pkg-add is unavailable; install Omarchy first" >&2
    exit 1
  fi
}

install_shell_framework() {
  local custom_plugins="$HOME/.oh-my-zsh/custom/plugins"

  if [[ ! -f $HOME/.oh-my-zsh/oh-my-zsh.sh && -e $HOME/.oh-my-zsh ]]; then
    echo "error: ~/.oh-my-zsh exists but is not a complete Oh My Zsh installation" >&2
    echo "Move it aside or repair it, then run recovery again." >&2
    exit 1
  elif [[ ! -f $HOME/.oh-my-zsh/oh-my-zsh.sh ]]; then
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  fi

  mkdir -p "$custom_plugins"

  if [[ ! -f $custom_plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh && -e $custom_plugins/zsh-autosuggestions ]]; then
    echo "error: the zsh-autosuggestions plugin path exists but is incomplete" >&2
    exit 1
  elif [[ ! -f $custom_plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh ]]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
      "$custom_plugins/zsh-autosuggestions"
  fi

  if [[ ! -f $custom_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh && -e $custom_plugins/zsh-syntax-highlighting ]]; then
    echo "error: the zsh-syntax-highlighting plugin path exists but is incomplete" >&2
    exit 1
  elif [[ ! -f $custom_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh ]]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
      "$custom_plugins/zsh-syntax-highlighting"
  fi
}

backup_collisions() {
  local backup_root=$1
  local source_path relative_path target_path source_real target_real target_link_source

  while IFS= read -r -d '' source_path; do
    relative_path=${source_path#"$DOTFILES_DIR"/}
    target_path="$HOME/$relative_path"

    [[ -e $target_path && $target_path -ef $source_path ]] && continue

    if [[ -L $target_path ]]; then
      source_real=$(readlink -f "$source_path" 2>/dev/null || true)
      target_real=$(readlink -f "$target_path" 2>/dev/null || true)
      target_link_source=$(realpath -ms "$(dirname -- "$target_path")/$(readlink "$target_path")")
      [[ $target_link_source == "$source_path" ]] && continue
      [[ -n $source_real && $source_real == "$target_real" ]] && continue
    elif [[ ! -e $target_path ]]; then
      continue
    fi

    mkdir -p "$backup_root/$(dirname -- "$relative_path")"
    mv -- "$target_path" "$backup_root/$relative_path"
    printf 'backed up: %s\n' "$relative_path"
  done < <(find "$DOTFILES_DIR" \( -type f -o -type l \) -print0)
}

remove_legacy_links() {
  local legacy_name legacy_path legacy_target

  for legacy_name in "${LEGACY_HYPR_LINKS[@]}"; do
    legacy_path="$HOME/.config/$legacy_name"
    legacy_target="$DOTFILES_DIR/.config/hypr/$legacy_name"

    if [[ -L $legacy_path && $(readlink -f "$legacy_path" 2>/dev/null || true) == "$legacy_target" ]]; then
      rm -- "$legacy_path"
      printf 'removed legacy link: %s\n' "$legacy_path"
    fi
  done
}

create_runtime_links() {
  mkdir -p "$HOME/.config/rofi"
  ln -sfn "$HOME/.config/omarchy/current/background" "$HOME/.config/rofi/.current_wallpaper"
}

link_dotfiles() {
  local backup_base backup_root

  if ! command -v stow >/dev/null 2>&1; then
    echo "error: GNU Stow is required before dotfiles can be linked" >&2
    echo "Run recovery with --apply, or install the stow package manually." >&2
    exit 1
  fi

  backup_base="$HOME/.local/state/omarchy/personal-backups"
  mkdir -p "$backup_base"
  backup_root=$(mktemp -d "$backup_base/$(date +%Y%m%d-%H%M%S)-XXXXXX")
  ACTIVE_BACKUP_ROOT=$backup_root

  backup_collisions "$backup_root"

  stow --restow --no-folding --dir="$DOTFILES_DIR" --target="$HOME" .
  remove_legacy_links
  create_runtime_links
  ACTIVE_BACKUP_ROOT=""

  if [[ -z $(find "$backup_root" -mindepth 1 -print -quit) ]]; then
    rmdir "$backup_root"
  else
    echo "Existing files were saved under: $backup_root"
  fi
}

confirm_changes() {
  local reply

  $ASSUME_YES && return
  read -r -p "Continue with recovery mode '$MODE'? [y/N] " reply
  [[ $reply == "y" || $reply == "Y" ]] || exit 0
}

check_repository

if [[ $MODE == "check" ]]; then
  exit "$status"
fi

confirm_changes

if [[ $MODE == "apply" ]]; then
  install_packages
  install_shell_framework
fi

report_command stow
link_dotfiles

echo
echo "Personal dotfiles recovered. Run this next:"
echo "  $PERSONAL_DIR/recover.sh --check"
echo "Then complete the hardware and theme checks in RECOVERY.md."
