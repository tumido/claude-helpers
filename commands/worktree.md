---
description: Start a new worktree — from a PR, issue, workflow failure, or free-form description
args: "[context — PR number, issue number, URL, or description]"
---

## Step 1: Determine context

If **args are provided**, parse them:

- PR reference (`#N`, `PR N`, or a URL containing `/pull/<N>`) →
  Step 2a.
- Issue reference (`issue N`, or a URL containing `/issues/<N>`) →
  Step 2b.
- Workflow run URL (containing `/actions/runs/`) → Step 2d.
- Bare number → ask whether it's a PR or issue, then route.
- Anything else → treat as free-form description, Step 2c.

If **no args**, use `AskUserQuestion`:

- Question: "What is this worktree for?"
- Options: "Continue an existing PR" / "Work on a GitHub issue" /
  "Start fresh work"
- Route accordingly. If the user types free text via "Other", re-parse
  using the rules above.

## Step 2a: Existing PR

If the PR number is not yet known, ask for it.

```bash
gh pr view <N> --json number,title,headRefName,baseRefName,state
```

If the PR is not open, warn and confirm. Set `<BRANCH>` to the PR's
`headRefName`.

Check if a worktree for this branch already exists:

```bash
git worktree list
```

Scan the output for a line containing `[<BRANCH>]`. If found, extract
the path from the beginning of that line and use `EnterWorktree` with
`path: "<existing-path>"`. Report reuse and stop.

Otherwise create the worktree on a local branch tracking the remote:

```bash
git fetch origin <BRANCH>
git worktree add .claude/worktrees/<BRANCH> <BRANCH>
```

Git auto-creates a local tracking branch from `origin/<BRANCH>` if
one doesn't exist yet. Use `EnterWorktree` with
`path: ".claude/worktrees/<BRANCH>"`.

Skip to Step 4.

## Step 2b: GitHub issue

If the issue number is not yet known, ask for it.

```bash
gh issue view <N> --json number,title,state
```

If closed, warn and confirm. Derive `<WORKTREE_NAME>` as
`<N>-<slugified-title>` (max 50 chars). Proceed to Step 3.

## Step 2c: Free-form work

Derive `<WORKTREE_NAME>` from the description (slugified, max 50
chars). If no description was given, ask what the work is about.

Confirm with `AskUserQuestion`:

- Question: "Use branch name `<WORKTREE_NAME>`?"
- Options: "Yes" / "Change it"

Proceed to Step 3.

## Step 2d: Workflow run failure

Extract the run ID from the URL and fetch details:

```bash
gh run view <RUN_ID> --json name,status,conclusion,headBranch,event,jobs
gh run view <RUN_ID> --log-failed 2>&1 | tail -100
```

Summarize the failure for the user. Derive `<WORKTREE_NAME>` from the
run context (e.g. `fix/<headBranch>-<failed-job-slug>`).

Confirm the branch name with `AskUserQuestion` (same as Step 2c).
Proceed to Step 3.

## Step 3: Choose base for the new branch

The worktree gets a **new branch** named `<WORKTREE_NAME>`. This step
picks its starting point — never check out `main` or `upstream/main`
directly.

Run in parallel:

1. `git branch --show-current`
2. `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`
   (fall back to `main` if it fails)

Use `AskUserQuestion`:

- Question: "What should `<WORKTREE_NAME>` be based on?"
- Options:
  - "Current branch (`<current-branch>`)"
  - "Main (`<default-branch>`)"
  - "Updated main from upstream"

### Option 1 — Current branch

```bash
git worktree add -b '<WORKTREE_NAME>' '.claude/worktrees/<WORKTREE_NAME>' HEAD
```

Use `EnterWorktree` with
`path: ".claude/worktrees/<WORKTREE_NAME>"`.

### Option 2 — Main

Use `EnterWorktree` with `name: "<WORKTREE_NAME>"` (branches from
`origin/<default-branch>` by default). Skip the manual commands below.

### Option 3 — Updated upstream main

Update the local default branch to match upstream, then push to origin
so `EnterWorktree` picks up the latest:

```bash
git remote get-url upstream 2>/dev/null && echo upstream || echo origin
git fetch <upstream-remote>
git rebase <upstream-remote>/<default-branch> <default-branch>
git push origin <default-branch>
```

Then use `EnterWorktree` with `name: "<WORKTREE_NAME>"` (same as
Option 2).

## Step 4: Confirm

Report the worktree path, branch name, and what it branched from.
Remind the user to run `/helpers:done` when finished.

## Rules

- Place worktrees under `.claude/worktrees/`.
- All git commands work directly in the worktree — do not `cd` back
  to the main repo root.
- For PR checkouts, preserve the original remote branch name.
