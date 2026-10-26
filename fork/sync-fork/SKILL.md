---
name: sync-omarchy-fork
description: Update a downstream fork of Omarchy (or any git fork that keeps its personal files in a GNU Stow package) from upstream without losing local modifications. Use when asked to "update my fork", "pull in upstream", "merge upstream into my branch", "sync with omarchy", or when a fork has drifted behind upstream and needs an audit before merging.
---

# Sync a fork with upstream

A fork like this one stays mergeable only because its local work lives in a
single Stow package that upstream never touches. A `git merge` of upstream is
therefore almost always *mechanically* clean — and that is exactly what makes it
dangerous: nothing in git reports the changes upstream made to files the fork
**shadows**, or the commands its overrides now collide with. This procedure
finds those before the merge, not after something breaks.

`fork/sync-fork/scripts/fork-sync` does the mechanical work. Read its output;
never merge on a green check alone.

## Before you start

Confirm the layout. Everything below is derived from it:

```bash
git remote -v                        # which remote is upstream?
git branch -vv                       # which branch are we on?
git merge-base --is-ancestor ...     # (fork-sync does all of this)
```

`fork-sync` auto-detects the upstream remote, upstream's default branch, and
the Stow package. Override detection when the guesses are wrong:

```bash
FORK_SYNC_UPSTREAM_REMOTE=upstream \
FORK_SYNC_UPSTREAM_BRANCH=quattro \
FORK_SYNC_STOW_DIR=dotfiles \
  fork/sync-fork/scripts/fork-sync audit
```

Facts specific to *this* fork — remotes, branch model, package model, and the
register of every intentional deviation — live in `REFERENCE.md` next to this
file. Read it before interpreting findings; update it as part of any change that
adds or removes a deviation.

## Procedure

### 1. Audit (always first, always read-only)

```bash
fork/sync-fork/scripts/fork-sync audit
```

Exit code 0 is clean, 1 is warnings only, 2 means a blocker. Never merge without
a baseline audit: after the merge you cannot tell what was already broken.

### 2. Read the findings in this order

| Section | What matters |
| --- | --- |
| Repository state | Divergence, and whether the merge conflicts at all. A conflict means local work escaped the Stow package — fix that first. |
| What the fork changes | Any **modified or deleted** upstream-shipped file is merge risk. Files *added* under the Stow package are not. |
| Shadowed files | Every fork file that replaces a shipped one. These are the only places upstream edits can go missing. |
| Keybinding collisions | Double-bound keys (two actions on one key) and keys upstream moved that the fork also uses. |
| Drift | Upstream code lines the fork's copies never received. Silent feature loss. |
| Hygiene | Stow conflicts, refresh hazards, tracked runtime state, dangling references. |

### 3. Merge

The fork must have a clean worktree. `fork-sync merge` refuses a dirty tree,
checks for conflicts with a worktree-free dry run, tags a backup branch, and
only then merges:

```bash
fork/sync-fork/scripts/fork-sync merge
```

If it reports a conflict, do not hand-resolve blindly. The usual cause is a
local commit reaching outside the Stow package — find it with
`git diff --name-only $(git merge-base HEAD upstream/<branch>) HEAD`, move that
work into the Stow package (or into a fork-only directory upstream never
touches), and re-run.

### 4. Reconcile — the step that actually needs judgement

Re-run the audit after merging. The *upstream* side of the report is now
current, so this is the real reconciliation pass:

```bash
fork/sync-fork/scripts/fork-sync keybinds
fork/sync-fork/scripts/fork-sync drift
```

For each finding, choose deliberately:

| Finding | Action |
| --- | --- |
| Double-bound key (`COLLISION`) | Add `hl.unbind("KEY")` before the local `o.bind`, or use `o.rebind`, or move the local action to a free key. Never leave two actions on one key. |
| Key upstream moved that the fork overrides | Re-check the collision. Upstream may have taken the key the fork now wants. |
| Drift: a missing upstream line in a shadowed file | Port the line into the fork's copy, or record why it is deliberately not wanted. |
| Drift: a removed upstream line still in the fork's copy | Delete it unless it still does something. |
| New upstream command that the fork's `.local/bin` shadows | Compare both; adopt upstream and delete the fork copy if upstream now does the same thing. |
| Upstream keybind change the fork does not touch | Nothing to do — but read it, it changes muscle memory. |

Every deliberate deviation you keep goes in the register in `REFERENCE.md` with
a one-line reason. A deviation without a reason is a bug waiting to be merged
away.

Where behaviour exists upstream, prefer *adopting* it over shadowing a whole
file. A fork-specific `.local/bin/foo` that shadows a shipped `bin/foo` silently
stops receiving upstream fixes; a one-line addition to a config that upstream
treats as a template does not.

### 5. Apply

Only after the reconciliation is committed:

```bash
fork/sync-fork/scripts/fork-sync apply          # asks first
fork/sync-fork/scripts/fork-sync apply --yes    # unattended
```

It re-stows the package, reloads Hyprland, and restarts the desktop shell.
Package updates (the Omarchy runtime itself) are a *separate* mechanism — let
`pacman -Syu` / the distro updater handle those. Do not assume merging the git
fork updates the running system; check `REFERENCE.md` for how the live tree is
installed on this machine.

### 6. Verify

A merge that re-stows config is a visual change. Confirm in the running
session, not just in tests:

- The desktop shell restarted and the bar is populated (no blank bar).
- Keybindings the reconciliation touched do what you chose, and the old action
  is gone.
- Terminal, launcher, file manager, screenshot, and the settings panels open.
- Nothing logs a Lua error: the Hyprland config must have reloaded cleanly.

If the session is unusable, recover from the shell's TTY:
`git reset --hard <pre-merge-backup-branch>` and re-stow.

### 7. Record

Update `REFERENCE.md`: the new merge base, any deviation added or removed, any
new known issue. The next run starts from this record instead of re-deriving it.

## Hard rules

- **Never** run `omarchy-refresh-config <path>` on a file that is a symlink into
  the fork. `cp` follows the symlink, so it overwrites the fork's copy with
  upstream's default — the modification is lost, and only `git status` shows it.
- **Never** `git checkout upstream/<branch> -- <stow-root>/` or reset the fork
  branch to upstream. The Stow package is the fork's whole value.
- **Never** keep local edits outside the Stow package. That is the one thing
  that turns a conflict-free merge into a conflicted one.
- **Never** merge with a dirty worktree; the backup branch would capture a state
  that does not exist anywhere else.
- Do not delete a deviation just because upstream moved something nearby. Ask
  what the local file was for first; the reason is in the register.

## Failure modes and what they mean

| Symptom | Cause |
| --- | --- |
| `merge` reports conflicts | Local work left the Stow package, or upstream renamed a directory the fork tracks. |
| Blank bar / no shell after apply | The shell config failed to load. Check `~/.local/state` logs; re-run `apply`, then reset to the backup branch if it persists. |
| A keybinding does nothing | A leftover `hl.unbind` with no matching `o.bind`, or the action binary is missing. |
| A setting "does not update" after a package update | The file shadows an upstream-shipped file. Port the upstream change by hand; do not run `omarchy-refresh-config`. |
| Two copies of a long-running process | A local autostart duplicates one upstream now starts itself. |
| Second, unexpected shell/panel process | A local autostart launches a component the distro also launches. Check with `pgrep -af <process>`. |
