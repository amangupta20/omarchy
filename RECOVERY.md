# Recovering This Omarchy Fork

This guide restores the personal setup carried by this fork without changing
files owned by upstream Omarchy. Recovery-specific code lives in `personal/`,
and personal configuration lives in `dotfiles/`. Keeping those paths separate
means normal merges from `basecamp/omarchy` should rarely conflict with them.

## What recovery restores

- Bash and Zsh configuration
- Hyprland overrides and JaKooLit-derived helper scripts
- Waybar layouts and styles
- Rofi, Kitty, Fastfetch, Neovim, and Quickshell configuration
- Personal packages listed in `personal/packages.txt`

It does not restore credentials, browser data, application databases, or other
private state. It also does not automatically guess the correct monitor or GPU
configuration for different hardware.

Some imported JaKooLit scripts are retained as optional utilities and refer to
components that are not part of the active desktop path. Recovery installs the
dependencies used by the selected Hyprland, Waybar, wallpaper, notification,
and shell configuration; it does not promise that every archived alternative
layout or legacy helper works unchanged.

## Fresh PC

Start with a normal Omarchy installation, but tell the installer to clone this
fork instead of Basecamp's repository:

```bash
OMARCHY_REPO=amangupta20/omarchy bash <(curl -Ls https://omarchy.org/boot.sh)
```

After the installation and first login, inspect recovery without changing
anything:

```bash
~/.local/share/omarchy/personal/recover.sh --check
```

To test the complete linking and collision-backup process in a disposable home
directory without touching the live configuration:

```bash
~/.local/share/omarchy/personal/test-recovery.sh
```

Install the personal dependencies and link the dotfiles:

```bash
~/.local/share/omarchy/personal/recover.sh --apply
```

Full recovery also installs Oh My Zsh and clones the two plugins referenced by
the tracked Zsh configuration into `~/.oh-my-zsh/custom/plugins`.

The script backs up conflicting files under:

```text
~/.local/state/omarchy/personal-backups/<timestamp>/
```

If linking fails after files have been moved into that backup, recovery restores
the displaced files automatically before exiting with an error.

It uses `stow --no-folding`, so it links individual configuration entries and
never replaces the entire `~/.config` directory with one symlink.
It also removes only the known wrong-level `~/.config/*.conf` symlinks created
by the old Stow invocation, leaving unrelated files untouched.

If packages are already installed, link only the dotfiles:

```bash
~/.local/share/omarchy/personal/recover.sh --link
```

## Hardware checks

Before relying on the recovered Hyprland session, inspect these files:

```text
~/.config/hypr/monitors.conf
~/.config/hypr/input.conf
~/.config/hypr/hyprland.conf
```

The tracked setup includes NVIDIA environment variables, a named USB mouse,
and monitor settings from the original machine. Adjust them if the new PC has
different hardware. Then validate Hyprland:

```bash
hyprctl reload
hyprctl configerrors
```

Restart the user-interface components after validation:

```bash
omarchy restart waybar
omarchy restart walker
```

## Theme and wallpaper

The active Omarchy theme is generated runtime state and is not fully stored in
Git. Select or regenerate the desired theme after recovery. This machine uses
the `omazed` theme hook when that program is installed.

Set a valid wallpaper once after recovery so AWWW and Rofi create their local
wallpaper state:

```bash
omarchy theme bg set
```

Do not commit `.current_wallpaper`, AWWW cache files, or generated wallpaper
effects. They are machine-local state.

## Credentials and local environment

Never place tokens in `dotfiles/.zshrc`. For machine-local shell variables:

```bash
mkdir -p ~/.config/omarchy
cp ~/.local/share/omarchy/personal/private-shell.zsh.example \
  ~/.config/omarchy/private-shell.zsh
chmod 600 ~/.config/omarchy/private-shell.zsh
```

Edit that copied file locally. It is sourced by `.zshrc` but is not part of the
repository.

## Keeping the fork updated

The installed `master` branch tracks this fork's `origin`, so ordinary updates
continue pulling personal commits:

```bash
omarchy update
```

For explicit upstream maintenance:

```bash
cd ~/.local/share/omarchy
git fetch upstream
git switch master
git merge upstream/master
git push origin master
```

Resolve upstream conflicts only in upstream-owned paths. Recovery additions
should remain under `personal/`, `dotfiles/`, and this `RECOVERY.md` file.

Avoid `omarchy reinstall git`: the current upstream implementation is hardcoded
to clone `basecamp/omarchy` and would replace this checkout with stock Omarchy.
If source recovery is needed, clone this fork manually instead.

## Capturing later changes

Because recovered files are symlinked into the repository, changes to them show
up directly in Git:

```bash
cd ~/.local/share/omarchy
git status --short
git diff
```

Review changes carefully, ensure no credentials or generated files are present,
then commit and push them to `origin`. A different PC can only recover changes
that have been committed and pushed.

Run the recovery audit at any time:

```bash
~/.local/share/omarchy/personal/recover.sh --check
```
