---
name: gh-stack
description: |
  Create and manage stacked pull requests with GitHub's official `gh stack`
  CLI extension (github/gh-stack) - a chain of PRs where each branch is
  based on the one below it, so a large change ships as independently
  reviewable layers. Use when the user says "stack these PRs", "create a
  stacked PR", "/gh-stack", "add this to the stack", or wants to check/sync/
  submit a stack of dependent branches.
metadata:
  requires: gh CLI >=2.90.0 (authenticated), git >=2.20, github/gh-stack extension
---

# gh stack

Thin wrapper around GitHub's own stacked-PR extension. It tracks the
branch chain locally and does the base-branch bookkeeping automatically -
don't hand-roll `git checkout -b` + `gh pr create --base <parent>` chains,
`gh stack` already does that.

## One-time setup

Check the extension is installed before the first use in a session:
```
gh extension list | grep gh-stack
```
If missing:
```
gh extension install github/gh-stack
```

## Workflow

1. **Start (or adopt into) a stack** - run once per stack, from the repo root:
   ```
   gh stack init                          # new stack off the default branch
   gh stack init --base develop           # new stack off a different trunk
   gh stack init feat/auth feat/api feat/ui   # adopt existing branches, bottom to top
   ```

2. **Add a layer** after making changes for that layer:
   ```
   gh stack add -Am "commit message" branch-name   # stage + commit + branch, one step
   gh stack add branch-name                        # branch already has committed changes
   ```
   Repeat for each logical layer, committing on top of the previous one.

3. **Submit the stack** - pushes every branch and creates/updates one PR per
   layer, each based on the layer below:
   ```
   gh stack submit
   ```
   This opens an interactive picker (title/description/draft per PR) unless
   run non-interactively or with `--auto` (auto-generated titles, new PRs as
   drafts). **Confirm with the user before running this** - it pushes
   branches and opens/updates real PRs, same as any other PR-creation skill.

4. **Check status any time:**
   ```
   gh stack view            # interactive table: branches, PRs, status
   gh stack view --short    # one line per branch
   ```

5. **Keep in sync with remote** (after review feedback lands, or PRs merge):
   ```
   gh stack sync            # fetch, rebase, push, re-link stack on GitHub
   gh stack sync --prune    # also delete local branches for merged PRs
   ```
   Never opens PRs itself - only `submit` does that.

## Navigation helpers

`gh stack top` / `bottom` / `up` / `down` / `trunk` check out branches
relative to your position in the stack. `gh stack switch` gives an
interactive picker.

## Notes

- If the user has one large, already-written branch that needs to be split
  into a stack (rather than building the stack incrementally), that's a
  planning problem, not a mechanical one - use the `decompose-pr` skill to
  decide the split, then use `gh stack add` for each resulting chunk instead
  of its manual `git`/`gh pr create --base` steps.
- A rebase conflict during `sync` restores all branches to their prior state;
  resolve with `gh stack rebase`, not manual git surgery.
