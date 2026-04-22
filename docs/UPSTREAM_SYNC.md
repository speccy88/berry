# Upstream Sync

## Goal

This fork is the main repo users clone, but it should still stay easy to sync with upstream Berry.

## Add the Upstream Remote

```sh
bash scripts/sync-upstream.sh
```

Or manually:

```sh
git remote add upstream https://github.com/berry-lang/berry.git
git fetch upstream
```

On Windows PowerShell:

```powershell
.\scripts\sync-upstream.ps1
```

## Merge Policy

- Keep upstream Berry files as unchanged as possible.
- Prefer adding P2-specific code under `port/p2/`, `mk/`, `tools/p2/`, and `docs/`.
- Avoid editing `src/` unless the port truly requires it.
- If upstream Berry changes force a workaround, document that drift clearly in `port/p2/patches/`.

## Practical Workflow

1. Fetch upstream.
2. Merge or rebase upstream onto your working branch.
3. Resolve conflicts with a bias toward keeping upstream Berry files clean.
4. Re-apply any P2-only changes in isolated overrides or documented patches where possible.

## Rule of Thumb

If a P2 change can live outside core Berry, it should.
