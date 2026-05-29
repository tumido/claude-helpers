---
description: Exit the current worktree — remove the worktree directory but keep the branch
---

Leave the current worktree session and clean up the worktree directory.
The branch is preserved so work can continue later from the main repo.

## Step 1: Verify worktree session

Check if the current session is inside a worktree created by
`EnterWorktree`. If not, tell the user there is no active worktree
session to exit and stop.

## Step 2: Exit

Use the `ExitWorktree` tool with `action: "remove"`. This removes the
worktree directory and returns the session to the original working
directory. The branch remains intact.

If the worktree has uncommitted changes, `ExitWorktree` will refuse.
Use `AskUserQuestion`:

- Question: "Worktree has uncommitted changes. What do you want to do?"
- Options: "Commit changes" / "Discard changes"

If **commit**: run `/helpers:ship`, then retry `ExitWorktree` with
`action: "remove"`.

If **discard**: re-invoke `ExitWorktree` with `action: "remove"` and
`discard_changes: true`.
