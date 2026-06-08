---
description: Resume a previous worktree session — switch into an existing worktree based on prior context
args: "[branch name, PR number, or issue number]"
---

## Step 1: Identify the target

If **args provided**, parse them:

- PR reference → `gh pr view <N> --json headRefName --jq '.headRefName'`
- Issue reference → match branches starting with `<N>-`
- Anything else → treat as branch name/substring

If **no args**, infer from conversation context (branch names, PR
numbers, issue numbers). Fall through to Step 2 if nothing found.

## Step 2: Match a worktree

```bash
git worktree list
```

Filter for `.claude/worktrees/` entries. Substring-match the target
against the branch in brackets.

- **One match** → Step 3.
- **Multiple** → `AskUserQuestion` to pick.
- **None** → show available worktrees and ask. If no worktrees exist,
  suggest `/helpers:worktree` and stop.

## Step 3: Enter

Use `EnterWorktree` with `path: "<matched-path>"`. Report path and
branch. Remind about `/helpers:done`.
