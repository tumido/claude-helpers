---
description: Start implementing a GitHub issue — fetch context, analyze codebase, plan, and execute
args: <issue-number> [additional requirements]
---

Fetch a GitHub issue, analyze the codebase for relevant context, plan
the implementation, and execute it. The first argument is the issue
number. Any remaining text is treated as additional requirements or
constraints to apply on top of the issue description.

## Step 1: Parse arguments and fetch issue

Extract the issue number from the first argument. Everything after it
is additional requirements text (may be empty).

Fetch the issue:

```bash
gh issue view <N> --json title,body,labels,milestone,comments
```

Read the issue title, body, and comments to understand the full scope.
If the issue doesn't exist or is closed, tell the user and stop.

## Step 2: Workspace setup

Use the `AskUserQuestion` tool with two questions in a single call:

1. **Workspace** — "Where should the work happen?"
   - Options: "New worktree" / "Current directory"

2. **Branch** — "Which branch?"
   - Options: "New branch" (suggest a name derived from the issue:
     `<N>-<slugified-title>`, e.g. `42-add-token-refresh`) /
     "Current branch"

Apply the choices:

- If **new worktree**: use the `EnterWorktree` tool with the branch
  name as the worktree name.
- If **current directory + new branch**:

  ```bash
  git checkout -b '<branch-name>'
  ```

- If **current directory + current branch**: proceed as-is.

## Step 3: Analyze codebase

Launch 2-3 `Explore` subagents **in parallel** (send all Agent tool
calls in a single message). Each agent receives the issue title, body,
and the additional requirements so it can focus its search.

**Agent 1 — Project structure**: Investigate the project layout, tech
stack, build system, entry points, and key configuration files.
Identify architectural patterns and conventions.

**Agent 2 — Relevant code**: Search for code areas directly related to
the issue. Grep for keywords from the issue title and body, find
related files, existing implementations, and test patterns. Trace code
paths that will need modification.

**Agent 3** (only if the issue references specific components, modules,
or files): Deep-dive into those specific areas — read the files, map
dependencies, understand the interfaces.

Wait for all agents to complete before proceeding.

## Step 4: Plan implementation

Use `EnterPlanMode` to design the implementation approach. The plan
must incorporate:

- Findings from the explore agents (file paths, patterns, conventions)
- Requirements from the issue body
- Additional constraints from the command arguments
- Existing patterns to follow and utilities to reuse

Write the plan and call `ExitPlanMode` to present it to the user for
approval. Do not proceed until the user approves.

## Git in worktrees

A worktree is a full git working tree — all git commands (`log`,
`diff`, `status`, `branch`, etc.) work directly from the worktree
directory. Do **not** `cd` back to the main repo root to run git
commands; it is unnecessary and triggers extra permission prompts.

```bash
# Good — run directly in the worktree
git log --oneline -5
git diff main

# Bad — unnecessary cd to repo root
cd /path/to/repo && git log worktree-branch --oneline -5
```

## Step 5: Execute

Implement the approved plan in the main context. Follow the project's
existing patterns and conventions identified in Step 3.

After implementation, briefly summarize what was done and suggest
running `/helpers:ship` to commit and open a PR.

## Step 6: Clean up worktree

If the session started in a worktree (Step 2), ask the user before
removing it. Use `AskUserQuestion`:

- Question: "Remove the worktree and return to the main repo?"
- Options: "Yes, remove worktree" / "No, keep it"

If **yes**: run `/helpers:done`.
If **no**: leave the worktree in place and let the user know they can
run `/helpers:done` later when ready.
