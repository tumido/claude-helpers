---
description: Rebase all open PRs onto the updated default branch — fetch upstream, update main, rebase PRs in parallel
---

Fetch the latest upstream default branch, rebase and push the local
default branch, then rebase every open PR by the current user in
parallel using worktree agents.

## Step 1: Assess git state

Run all of these in parallel:

1. **Upstream remote** —
   `git remote get-url upstream 2>/dev/null && echo upstream || echo origin`.
   Save the result as the fetch remote.

2. **Default branch** —
   `git rev-parse --abbrev-ref origin/HEAD` to find the remote default
   branch (e.g., `origin/main`). Strip the `origin/` prefix to get the
   local name. Fall back to `main` if unset.

3. **Current branch** — `git branch --show-current`.

If the current branch is **not** the default branch, use
`AskUserQuestion`:

- Question: "You're on `<current-branch>`, not `<default-branch>`.
  Switch to the default branch to continue?"
- Options: "Yes, switch" / "Abort"

If switching:

```bash
git checkout '<default-branch>'
```

If aborted, stop.

## Step 2: Update local default branch

Fetch from the upstream remote and rebase:

```bash
git fetch <upstream-remote>
git rebase <upstream-remote>/<default-branch>
```

If the rebase produces conflicts, resolve them (edit conflicting files,
`git add`, `git rebase --continue`) and repeat until the rebase
completes cleanly.

Push the updated default branch to origin:

```bash
git push origin <default-branch>
```

## Step 3: List open PRs

Fetch all open PRs authored by the current user:

```bash
gh pr list --author '@me' --state open --json number,title,headRefName,baseRefName --limit 100
```

Filter the JSON output to keep only PRs where `baseRefName` equals the
default branch name. PRs targeting other branches are out of scope —
mention them to the user if any are skipped.

If no qualifying PRs exist, report "No open PRs targeting
`<default-branch>`" and stop.

Present the list and confirm using `AskUserQuestion`:

- Question: "Rebase these PRs onto the updated `<default-branch>`?"
  Show each PR's number, title, and branch in the description.
- Options: "Yes, rebase all" / "Abort"

If aborted, stop.

## Step 4: Prepare agent context

Read `CLAUDE.md` at the project root (if it exists) and extract the
test command. Also note any lint commands. These will be passed into
each agent's prompt so agents don't discover them independently.

If no `CLAUDE.md` exists or no test command is documented, set the test
instruction to: "No test command configured — skip testing."

Record the absolute path to the main working tree:

```bash
pwd
```

## Step 5: Check for existing worktrees

List all active worktrees:

```bash
git worktree list
```

For each PR branch from Step 3, check if a worktree already exists
whose checked-out branch matches the PR's `headRefName`. Build two
lists:

- **Existing worktree PRs** — PRs that already have a matching
  worktree. Record the worktree path for each.
- **New worktree PRs** — PRs with no existing worktree.

## Step 6: Spawn parallel worktree agents

For each PR, spawn an `Agent` — send **all Agent tool calls in a
single message** so they run in parallel.

- For PRs **with an existing worktree**: the agent does **not** use
  `isolation: "worktree"`. Instead, instruct the agent to enter the
  existing worktree using `EnterWorktree` with
  `path: "<worktree-path>"` and when done use `ExitWorktree` with
  `action: "keep"`. Use `mode: "bypassPermissions"`.
- For PRs **without an existing worktree**: the agent uses
  `isolation: "worktree"` and `mode: "bypassPermissions"`.

The prompt for each agent (fill in the placeholders):

---

Rebase PR #`<NUMBER>` (branch: `<BRANCH>`) onto `<DEFAULT_BRANCH>`.

**If entering an existing worktree** (only when the agent prompt
includes a worktree path):

Use the `EnterWorktree` tool with `path: "<WORKTREE_PATH>"` to enter
the existing worktree. The branch is already checked out — skip
straight to checking if rebase is needed.

**If in a fresh worktree** (created via `isolation: "worktree"`):

```bash
git fetch origin <BRANCH>
git checkout <BRANCH>
```

**1. Check if rebase is needed:**

```bash
git merge-base --is-ancestor <DEFAULT_BRANCH> HEAD && echo up-to-date || echo needs-rebase
```

If the output is `up-to-date`, report "already up-to-date" and stop.

**2. Rebase onto the default branch:**

```bash
git rebase <DEFAULT_BRANCH>
```

If conflicts arise:
- Read the conflicting files and understand both sides of the conflict
- Edit to produce a correct resolution that preserves the intent of
  both the PR changes and the upstream changes
- `git add <resolved-files>`
- `git rebase --continue`
- Repeat until the rebase completes

If a conflict is ambiguous and cannot be resolved confidently,
`git rebase --abort` and report "unresolvable conflicts — needs manual
intervention".

**3. Run tests:**

`<TEST_COMMAND>` (or "No test command configured — skip testing.")

If tests fail, read the failure output and attempt to fix. If the fix
succeeds and tests pass on retry, continue. If tests still fail,
report "tests failed after rebase" with a brief summary of the
failures. Do **not** push if tests fail.

**4. Force-push:**

```bash
git push --force-with-lease
```

**5. Exit worktree (existing worktrees only):**

If you entered an existing worktree via `EnterWorktree`, use
`ExitWorktree` with `action: "keep"` to return to the original
directory. Skip this for `isolation: "worktree"` agents — cleanup is
automatic.

**6. Report** a single summary line:

`PR #<NUMBER> (<BRANCH>): <RESULT>`

Where RESULT is one of:
- `rebased and pushed`
- `rebased with conflict resolution and pushed`
- `already up-to-date`
- `rebase failed: <reason>`
- `tests failed: <summary>`

---

## Step 7: Collect results and report

After all agents complete, present a summary table:

```
| PR   | Title   | Branch   | Result           |
|------|---------|----------|------------------|
| #N   | ...     | ...      | rebased and pushed |
```

Group by outcome: successful rebases first, then already-up-to-date,
then failures. For failures, include a brief explanation so the user
can follow up.

## Rules

- Never skip tests if a test command is configured — a broken PR is
  worse than a stale one.
- Never force-push a branch where tests fail.
- Use `--force-with-lease` exclusively — never `--force`.
- Worktree agents with `isolation: "worktree"` are cleaned up
  automatically — no explicit cleanup step is needed.
- If `gh` is not available, fall back to telling the user to install
  it.
