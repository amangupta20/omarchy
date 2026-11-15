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
| `hypr/bindings.lua` | replaces upstream defaults incl. `SUPER + SHIFT + TAB`, adds fork-only keys | Personal layout. See the keybinding table below. |
| `hypr/input.lua` | `repeat_delay = 600`; touchpad `natural_scroll`, `scroll_factor = 0.4`; per-device sensitivity `-0.35` for `instant-usb-gaming-mouse-` | Personal feel. Note it *drops* upstream's `kb_layout`, `repeat_rate`, `numlock_by_default`, `sensitivity`, `accel_profile`, `clickfinger_behavior`, `disable_while_typing`, `drag_3fg`. |
| `hypr/looknfeel.lua` | `gaps_in = 1`, `gaps_out = 2`, `border_size = 2`; `cursor.no_hardware_cursors`, `cursor.use_cpu_buffer`; `xwayland.force_zero_scaling`; `XCURSOR_THEME`/`HYPRCURSOR_THEME` = `Adwaita` | Visible gaps; hardware cursor renders blank under fractional scaling; XWayland apps misjudge cursor size/position. |
| `hypr/monitors.lua` | `scale = 1.25`, `GDK_SCALE = 1.25` on top of upstream's monitor-panel template | 1.25 fractional scaling on this panel; template ported from upstream `b083e16a7` so panel docs stay current. |
| `environment.d/backlight.conf` | `OMARCHY_BACKLIGHT_PATH=...` | Same value as `hyprland.lua` sets; kept so non-Hyprland consumers see it too. |
| `omarchy/backlight/acpi_video1` | symlink → `/sys/class/backlight/acpi_video1` | The directory the backlight override points at, holding only the Intel iGPU node. |

### Shadowed shipped command (`bin/` → `~/.local/bin/`)

| File | What is changed | Why |
| --- | --- | --- |
| `omarchy-theme-bg-switcher` | adds `"$HOME/Pictures/wallpapers"` to the `omarchy-menu-images` directory list | Surface personal wallpapers in the background switcher. **Shadows `bin/omarchy-theme-bg-switcher` on PATH**, so upstream changes to that script never reach it. Re-check after every merge. |
| `omarchy-launch-files`, `omarchy-launch-files-cwd` | run `nautilus --new-window` instead of `folio` | User kept Nautilus over upstream's Folio. Hyprland's PATH puts `/usr/share/omarchy/bin` first, so the shadows only win in terminals — `bindings.lua` calls them by absolute `~/.local/bin` path for `SUPER + F` and `SUPER + ALT + SHIFT + F`. Re-check after every merge. |

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
| `.config/omarchy/hooks/theme-set.d/20-yaru-icons` | theme-set hook that puts back each theme's pre-`72922629a` Yaru icon colour (Catppuccin → `Yaru-purple`) after `omarchy-theme-set-gnome` resets icons to Adwaita | User prefers the old Yaru folders in Nautilus; needs `yaru-icon-theme` (installed explicitly 2026-11-15), keeps Adwaita if it is missing. GTK only — Qt apps stay on Adwaita |
| `.local/bin/acer-fan-curve` + `.config/systemd/user/acer-fan-curve.service` | temperature-driven fan curve for the Acer Nitro AN515-58 via `linuwu_sense` | EC holds fans low while CPU hits 90s; polls temps (no change signal exists), drives both fans from hotter of CPU/dGPU, restores EC auto on exit |

### Packages upstream removed that the fork needs

Upstream dropped these. Their removal migrations (`1794330979` Nautilus, `1794397144` Yaru) already ran here and are one-shot, so the explicitly reinstalled packages stay. A fresh Omarchy install never gets them; install them before stowing:

```bash
omarchy-pkg-add nautilus yaru-icon-theme
```

- `nautilus`: the file manager behind the shadowed `omarchy-launch-files(-cwd)`.
- `yaru-icon-theme`: icons for the `20-yaru-icons` theme-set hook. It covers native GTK apps (Nautilus, Papers, Disks, gedit, Mission Center, Celluloid, Clapper, Pinta, Remmina, Seahorse, Lutris, Xournal++, GParted, Tsukimi, nwg-displays) and the GTK file picker in browsers and Electron apps.

### Keybinding map

Replaced upstream defaults (each preceded by `hl.unbind`):

| Key | Upstream | Fork |
| --- | --- | --- |
| `SUPER + Q` | Close window | Close active window |
| `SUPER + A` | Select all | Workspace overview (`quickshell:overviewToggle`) |
| `SUPER + W` | Close window | Wallpaper selector (`UserScripts/WallpaperSelect.sh`) |
| `SUPER + SHIFT + W` | Omawrite | Wallpaper effects (`UserScripts/WallpaperEffects.sh`) |
| `SUPER + F` | Full screen | File manager (Nautilus, deliberately kept — see below) |
| `SUPER + SHIFT + F` | File manager | Full screen |
| `SUPER + ALT + SHIFT + F` | File manager (cwd), Folio | File manager (cwd), Nautilus via the `~/.local/bin` shadow |
| `SUPER + SHIFT + B` | Browser | Browser (private) |
| `SUPER + SHIFT + A` | ChatGPT | Grok |
| `SUPER + SHIFT + X` | X | X Post |
| `SUPER + SHIFT + TAB` | Previous workspace | Last used workspace on this monitor (press again to flip back) |

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

- **Nautilus removal (2026-11-13) — user kept Nautilus.** Upstream `795dfb234` +
  migration `1794330979` removed Nautilus during the package update to
  `3f974d011`. The user tried Folio, Dolphin and COSMIC Files and chose to
  stay on Nautilus: package reinstalled explicitly (`omarchy-pkg-add nautilus`),
  so the one-shot migration will not remove it again. `SUPER + F` runs
  `nautilus --new-window` (through the shadowed `omarchy-launch-files`),
  `inode/directory` and `application/zip` in `~/.config/mimeapps.list` point at
  `org.gnome.Nautilus.desktop`, and the dock pin is `org.gnome.Nautilus`
  (`omarchy dock pinned`, in the untracked `~/.config/omarchy/shell.json`).
  The Dropbox panel still opens files with a hardcoded `folio`. Standing deviation: upstream
  file-manager integration (dispatcher, previews, sharing) now targets Folio
  and will not flow to Nautilus; future migrations touching Nautilus need a
  manual check.
- `SUPER + ALT + G` was double-bound to Google Messages while upstream used it
  for "Move active window out of group". Fixed with `hl.unbind` first; verified
  live with `hyprctl -j binds` — only one entry remains at `modmask` 72.
- `.zshrc` aliased `recover`/`stower` to `~/.local/share/omarchy/personal/recover.sh`,
  which no longer exists anywhere; both aliases removed.

## Sync log

| Date | Upstream head | Result |
| --- | --- | --- |
| 2026-10-26 | `58858aecf` | 262 commits merged, 0 conflicts, 0 files touched under `dotfiles/`. Reconciliation: `SUPER + ALT + G` unbind, dead aliases dropped. |
| 2026-10-28 | `600ca8866` | 54 commits merged, 0 conflicts, 0 files touched under `dotfiles/`. Reconciliation: no action — `SUPER + comma` / `SUPER + ALT + comma` notification swap and Omasnap overlay fix flow through (files not shadowed); 7 `bin/` updates, none shadowed. |
| 2026-10-31 | `bda3aaf69` | 74 commits merged, 0 conflicts, 0 files touched under `dotfiles/`. Reconciliation: no action — no keybinding changes upstream, no drift in the 7 shadowed files. Semantic pass: dropped the fork's 3-finger horizontal `workspace` gesture from `input.lua` — upstream now ships 3-finger left/right workspace gestures (`default/hypr/gestures.lua`) and Hyprland rejects a second gesture on the same fingers/direction. `omarchy-hyprland-monitor-scaling` now writes per-monitor rules through the `monitors.lua` symlink into `dotfiles/` — expect repo diffs after scaling changes. |
| 2026-11-02 | `cf659d607` | 115 commits merged, 0 conflicts, 0 files touched under `dotfiles/`. Reconciliation: pre-merge local work committed first (SUPER+SHIFT+TAB previous-window, monitors.lua panel-template port keeping 1.25, new acer-fan-curve + service); post-merge `keybinds`/`drift` clean — upstream dictation (`ALT+SPACE`, dropped `F9`/`SUPER+CTRL+X`) and `XF86Display` keys flow through, `monitors.lua` 2 removed lines already ported, `omarchy-theme-bg-switcher` untouched upstream. |
| 2026-11-06 | `d5b32d24d` | 45 commits merged, 0 conflicts, 0 files touched under `dotfiles/`. Reconciliation: no action — post-merge `keybinds`/`drift` clean; upstream `CTRL + XF86MonBrightnessUp/Down` keyboard-backlight keys and `default/hypr/autostart.lua` software-rendering line flow through (files not shadowed); 37 `bin/` updates, none shadowed. |
| 2026-11-09 | `cbd0029fd` | 32 commits merged, 0 conflicts, 0 files touched under `dotfiles/`. Reconciliation: no action — post-merge `keybinds`/`drift` clean; upstream glassy-every-window (`default/hypr/*`, `bin/omarchy-hyprland-window-transparency`, `bin/omarchy-theme-set-glass`) and Herdr Desktop keymap (`keys.json`, not Hyprland bindings) flow through (files not shadowed); `bin/omarchy-theme-bg-switcher` and all 6 shipped `config/hypr/*.lua` counterparts untouched upstream. Installed `omarchy-dev` package already at `cbd0029`, so runtime matches the merge. |
| 2026-11-10 | `df3d01ce8` | 13 commits merged, 0 conflicts, 0 files touched under `dotfiles/`. Reconciliation: no action — post-merge `keybinds`/`drift` clean. Upstream dropped the blank startup cursor (`default/hypr/startup-cursor.lua` deleted, `autostart.lua` no longer swaps `XCURSOR_*`), which no longer competes with the fork's `Adwaita` cursor envs in `looknfeel.lua`; `QT_QPA_PLATFORMTHEME` moved `gtk3` → `qtengine` in `default/hypr/envs.lua` (fork sets no Qt envs; migration `1792902457` installs `qtengine`). 13 `bin/` updates, none shadowed. Installed `omarchy-dev` still at `cbd0029` — runtime is 13 commits behind until the package updates. |
| 2026-11-13 | `3f974d011` | 194 commits merged, 0 conflicts, 0 files touched under `dotfiles/`. Reconciliation: pre-merge local work committed first (SUPER+SHIFT+TAB previous-window function → `previous_per_monitor`, register updated); the `o.rebind` spelling tripped `fork-sync keybinds` (checker only credits `hl.unbind`), so normalized to `hl.unbind` + `o.bind` — behavior-identical, audit green. Post-merge `keybinds`/`drift` clean; upstream Agents panel (`SUPER + CTRL + X`) and Files-as-file-manager dispatcher flow through (fork overrides neither chord). 50 `bin/` updates, none shadowed (`omarchy-theme-bg-switcher` untouched). Pending: Nautilus removal on next package update (known issue 4). Installed `omarchy-dev` still at `df3d01c` — runtime is 194 commits behind until the package updates. |

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
that turns a conflict-free merge into a conflicted one. `.power/` and
`dotfiles/.config/hypr/monitors.lua.bak*` are excluded this way today.

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
