# Fork reference

Pinned facts about this fork, and the register of every intentional deviation
from upstream. `SKILL.md` is the procedure; this file is the ground truth it
reads against. Update it as part of any change that adds or removes a deviation.

Re-derive the mechanical half at any time with `fork-sync state` and
`fork-sync inventory`; the deviation register below is the half that cannot be
derived and therefore must be maintained by hand.

## Layout

| Thing | Value |
| --- | --- |
| Working copy | `~/omarchy` |
| Fork remote | `origin` → `github.com/amangupta20/omarchy` |
| Upstream remote | `upstream` → `github.com/basecamp/omarchy` |
| Upstream default branch | **`quattro`** — upstream has no `master`; `refs/remotes/upstream/HEAD` is stale and still points at `master` |
| Fork branch | `quattro-custom`, tracks `origin/quattro-custom` |
| Stow package | `dotfiles/` — stowed into `$HOME` with `stow -t "$HOME" -d dotfiles .` |
| Stow control | `dotfiles/.stow-local-ignore` excludes runtime wallpaper state and `acpi_video1` |

Legacy branches to leave alone: `master` (the pre-Quattro v3 line),
`pre-merge-backup` (a hand-made snapshot).

The fork's entire divergence from upstream is files *added* under `dotfiles/`.
No upstream-shipped file is modified, which is why merges have been
conflict-free. Preserve that property.

## How the running system is installed

Merging the git fork does **not** update the running Omarchy runtime:

- The live tree is `/usr/share/omarchy` (`OMARCHY_PATH`), owned by the
  `omarchy-dev` package, built from an upstream commit.
- `omarchy dev status` reports `dev-link: inactive`, so nothing in the working
  copy is live except what Stow links into `$HOME`.
- The runtime therefore tracks the package, not this branch. Package updates
  arrive through `pacman`/the updater; the fork contributes only the Stow
  package and, when actively linked, `omarchy dev link`.

Check after a merge whether the installed package is behind upstream — a git
fork that is up to date still runs old code if the package has not moved.

## Deviation register

Every live file here is a symlink into `dotfiles/`. These are the only places
an upstream change can go missing.

### Shadowed shipped configs (`config/` → `~/.config/`)

These replace an upstream template wholesale. Upstream's versions are mostly
comment templates, so drift is usually silent rather than harmful — but check
`fork-sync drift` after every merge.

| File | What is changed | Why |
| --- | --- | --- |
| `hypr/hyprland.lua` | sets `OMARCHY_BACKLIGHT_PATH` to `~/.config/omarchy/backlight` before requiring the defaults | Hybrid graphics: Omarchy picks the wrong backlight node when the dGPU also exposes one. |
| `hypr/autostart.lua` | launches `quickshell` and `wl-clip-persist --clipboard regular --reconnect-tries inf` | `quickshell` backs the SUPER+A overview (see below); `wl-clip-persist` keeps the clipboard source alive so Omarchy's clipboard history still captures after the copying app exits. |
| `hypr/bindings.lua` | replaces 11 upstream defaults, adds 5 fork-only keys | Personal layout. See the keybinding table below. |
| `hypr/input.lua` | `repeat_delay = 600`; touchpad `natural_scroll`, `scroll_factor = 0.4`; 3-finger horizontal workspace gesture; per-device sensitivity `-0.35` for `instant-usb-gaming-mouse-` | Personal feel. Note it *drops* upstream's `kb_layout`, `repeat_rate`, `numlock_by_default`, `sensitivity`, `accel_profile`, `clickfinger_behavior`, `disable_while_typing`, `drag_3fg`. |
| `hypr/looknfeel.lua` | `gaps_in = 1`, `gaps_out = 2`, `border_size = 2`; `cursor.no_hardware_cursors`, `cursor.use_cpu_buffer`; `xwayland.force_zero_scaling`; `XCURSOR_THEME`/`HYPRCURSOR_THEME` = `Adwaita` | Visible gaps; hardware cursor renders blank under fractional scaling; XWayland apps misjudge cursor size/position. |
| `hypr/monitors.lua` | `scale = 1.25`, `GDK_SCALE = 1.25` | 1.25 fractional scaling on this panel. |
| `environment.d/backlight.conf` | `OMARCHY_BACKLIGHT_PATH=...` | Same value as `hyprland.lua` sets; kept so non-Hyprland consumers see it too. |
| `omarchy/backlight/acpi_video1` | symlink → `/sys/class/backlight/acpi_video1` | The directory the backlight override points at, holding only the Intel iGPU node. |

### Shadowed shipped command (`bin/` → `~/.local/bin/`)

| File | What is changed | Why |
| --- | --- | --- |
| `omarchy-theme-bg-switcher` | adds `"$HOME/Pictures/wallpapers"` to the `omarchy-menu-images` directory list | Surface personal wallpapers in the background switcher. **Shadows `bin/omarchy-theme-bg-switcher` on PATH**, so upstream changes to that script never reach it. Re-check after every merge. |

### Fork-only, no upstream counterpart

These cannot drift, but they can break against removed upstream commands.

| Path | What it is |
| --- | --- |
| `.zshrc` | shell environment |
| `.config/nvim/` | LazyVim setup |
| `.config/rofi/` | JaKooLit rofi themes and configs |
| `.config/fastfetch/` | fetch configs |
| `.config/quickshell/` | JaKooLit overview/search shell, launched by `autostart.lua`; provides the `quickshell:overviewToggle` global shortcut |
| `.config/hypr/UserScripts/` | JaKooLit wallpaper/rofi helper scripts, called from `bindings.lua` |

### Keybinding map

Replaced upstream defaults (each preceded by `hl.unbind`):

| Key | Upstream | Fork |
| --- | --- | --- |
| `SUPER + Q` | Close window | Close active window |
| `SUPER + A` | Select all | Workspace overview (`quickshell:overviewToggle`) |
| `SUPER + W` | Close window | Wallpaper selector (`UserScripts/WallpaperSelect.sh`) |
| `SUPER + SHIFT + W` | Omawrite | Wallpaper effects (`UserScripts/WallpaperEffects.sh`) |
| `SUPER + F` | Full screen | File manager (nautilus) |
| `SUPER + SHIFT + F` | File manager | Full screen |
| `SUPER + SHIFT + B` | Browser | Browser (private) |
| `SUPER + SHIFT + A` | ChatGPT | Grok |
| `SUPER + SHIFT + X` | X | X Post |

Unbound with no replacement: `SUPER + C`, `SUPER + X`.

Fork-only: `SUPER + B`, `SUPER + D`, `SUPER + E`, `SUPER + N`, `SUPER + Y`,
`SUPER + ALT + G` (after `hl.unbind`, because upstream uses that chord for
"Move active window out of group"; upstream's own Google Messages binding is
`SUPER + SHIFT + CTRL + G`).

## Known issues

Standing problems that the audit reports. Fix or explicitly accept; do not let
them drift out of this list.

1. **Two Quickshell processes run at once.** `autostart.lua` launches a bare
   `quickshell` (loading `~/.config/quickshell/shell.qml`, the JaKooLit
   overview) alongside Omarchy's own `quickshell -n -p $OMARCHY_PATH/shell`.
   Upstream's shell has no overview of its own, so the second shell is
   load-bearing — but it is a whole framework running for one feature and will
   silently break if upstream changes its shell API. Decision on record:
   leave it running, and investigate porting the overview into Omarchy's shell.
   Verify with `pgrep -af quickshell` — two hits is expected, not a bug.
2. **Runtime state tracked in git.** `dotfiles/.config/hypr/wallpaper_effects/`
   holds ~9 MB of wallpaper images that `.stow-local-ignore` stops Stow from
   linking — the tracked copies are dead weight. Same for
   `dotfiles/.config/fastfetch/config.jsonc.bak.1764780780`.
3. **`omarchy-refresh-config` is unsafe on any stowed file.** It `cp`s upstream's
   default over `~/.config/...`, which is a symlink here, so the write lands in
   the fork. Never run it on the six shadowed `hypr/*.lua` files.

Resolved:

- `SUPER + ALT + G` was double-bound to Google Messages while upstream used it
  for "Move active window out of group". Fixed with `hl.unbind` first; verified
  live with `hyprctl -j binds` — only one entry remains at `modmask` 72.
- `.zshrc` aliased `recover`/`stower` to `~/.local/share/omarchy/personal/recover.sh`,
  which no longer exists anywhere; both aliases removed.

## Sync log

| Date | Upstream head | Result |
| --- | --- | --- |
| 2026-10-26 | `58858aecf` | 262 commits merged, 0 conflicts, 0 files touched under `dotfiles/`. Reconciliation: `SUPER + ALT + G` unbind, dead aliases dropped. |

## Sync state

`fork/sync-fork/state/last-sync` records the upstream commit the fork last
merged. `fork-sync drift` and the "bindings that moved" report measure from
there, not from the merge base — otherwise a merge would advance the merge base
to upstream's tip and collapse those reports to nothing exactly when they are
still needed for reconciliation. `fork-sync merge` rewrites the file; commit it
with the merge commit.

## Local-only ignores

Untracked local state (`.power/`, editor droppings) belongs in
`.git/info/exclude`, never in the tracked `.gitignore`. Editing `.gitignore`
would be a modification to an upstream-shipped file, which is the one thing
that turns a conflict-free merge into a conflicted one. `.power/` is excluded
this way today.

## Re-deriving the mechanical facts

```bash
fork-sync state       # remotes, branch, divergence, conflicts, package
fork-sync inventory   # fork delta, live-vs-dormant, shadowed shipped files
fork-sync keybinds    # collisions and upstream key moves
fork-sync drift       # upstream lines the shadowed copies never received
fork-sync doctor      # stow hazards, tracked state, dangling references
```

`fork-sync` reads these values from the repository on every run, so this file
only needs updating when the *model* changes: a new remote, a different Stow
root, a deviation added or removed, or a known issue resolved.
