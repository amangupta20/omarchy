# fork/

Fork-only tooling. Upstream has no `fork/` directory, so nothing here can
conflict with a merge — keep it that way: everything personal goes either here
or in the Stow package, never into a file upstream ships.

## sync-fork/

Keeps this fork in step with `upstream/quattro` without losing local changes.

- `SKILL.md` — the procedure. Agent-agnostic; works in Claude Code, pi, Codex,
  Cursor, or by hand.
- `REFERENCE.md` — pinned facts about this fork and the register of every
  intentional deviation from upstream.
- `scripts/fork-sync` — the tool the procedure calls.

```bash
fork/sync-fork/scripts/fork-sync audit     # read-only; do this first
fork/sync-fork/scripts/fork-sync merge     # fetch, verify, merge
fork/sync-fork/scripts/fork-sync apply     # restow + reload the session
```

`fork-sync help` lists every subcommand. It auto-detects the upstream remote,
upstream's default branch, and the Stow package from the repository, so it is
not specific to this fork's names.

The skill is linked into the user-level skill directories so every agent on
this machine picks it up:

```
~/.agents/skills/sync-omarchy-fork -> ~/omarchy/fork/sync-fork
~/.claude/skills/sync-omarchy-fork -> ../../.agents/skills/sync-omarchy-fork
```
