# Lanternhouse Worktree Workflow

Worktrees let us keep several branches checked out at the same time. Each folder
is one branch with its own working files, but they all share the same Git repo
history.

## Current Layout

```text
I:\code\lanternhouse          main integration branch
I:\code\lanternhouse-gameplay gameplay and systems branch
I:\code\lanternhouse-art      art branch, if actively used
I:\code\lanternhouse-docs     docs branch, if actively used
```

The main rule: do work in a lane worktree, then merge that lane back into
`I:\code\lanternhouse` when it is tested and ready.

## Daily Commands

See all worktrees:

```powershell
git worktree list
```

Check what branch and changes a worktree has:

```powershell
git status --short --branch
```

Commit inside a lane:

```powershell
cd I:\code\lanternhouse-gameplay
git add <files>
git commit -m "Describe the slice"
git push
```

## Merging A Lane Into Main

Start from the integration worktree:

```powershell
cd I:\code\lanternhouse
git status --short --branch
git fetch origin
```

Merge the lane:

```powershell
git merge --no-ff codex-gameplay -m "Merge gameplay updates"
```

Run checks before pushing:

```powershell
godot --headless --path . --quit
godot --headless --path . scenes\dev\smoke_first_route_guidance.tscn
godot --headless --path . scenes\dev\smoke_overworld_command_menu.tscn
godot --headless --path . scenes\dev\smoke_dead_wick.tscn
```

Push main:

```powershell
git push origin main
```

## Updating A Lane After Main Changes

After main receives another branch, update your lane before continuing:

```powershell
cd I:\code\lanternhouse-gameplay
git fetch origin
git merge origin/main
```

If Git reports conflicts, open the files it names, keep the intended combined
version, then:

```powershell
git add <resolved-files>
git commit
```

## Creating A New Worktree

Use branch names that do not conflict with existing branch folders. If a branch
named `codex` exists, use `codex-gameplay` instead of `codex/gameplay`.

```powershell
cd I:\code\lanternhouse
git worktree add -b codex-new-slice I:\code\lanternhouse-new-slice main
git push -u origin codex-new-slice
```

## Removing A Finished Worktree

Only remove a worktree after its branch is merged or intentionally abandoned:

```powershell
cd I:\code\lanternhouse
git worktree remove I:\code\lanternhouse-new-slice
git branch -d codex-new-slice
git push origin --delete codex-new-slice
```

Use `git branch -D` only for a branch you are sure you do not need.

## Practical Rules

- Keep `main` clean and use it for integration.
- Do not edit the same large script in two worktrees at once if you can avoid it.
- Commit small slices before merging.
- Run smoke checks in `main` after merging.
- Leave generated `.import` or `.uid` files alone unless the change is deliberate.
- If a worktree looks messy, run `git status --short --branch` before doing
  anything else.
