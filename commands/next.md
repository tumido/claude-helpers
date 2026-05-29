---
description: Pick the next issue to work on from the project board and start implementing it
---

Find Ready items on the GitHub project board, recommend the best one
to work on next, assign it on confirmation, and kick off implementation.

## Step 1: Gather project metadata

1. **Repository** — `gh repo view --json owner,name`

2. **Project** — find the project number and fetch field IDs:

   ```bash
   gh project list --owner <OWNER> --format json
   bash $CLAUDE_HELPERS_DIR/scripts/gh-project-fields.sh <OWNER> <N>
   ```

   Save: project node ID, Status field ID, and option IDs for each
   status (Backlog, Ready, In progress, In review, Done).

3. **Milestones** — `gh api --method GET repos/:owner/:repo/milestones`
   to identify which milestone(s) are active.

## Step 2: Query Ready items

Fetch all project items (auto-paginates, flattened output) and filter
in one call:

```bash
bash $CLAUDE_HELPERS_DIR/scripts/gh-project-items.sh <OWNER> <N> \
  | jq '[.[] | select(.status == "Ready" and .state == "OPEN" and (.assignees | length == 0) and .parent == null)]'
```

## Step 3: Rank and recommend

From the filtered list, pick the best candidate using these priorities
(highest first):

1. **Active milestone** — issues in the current milestone beat those
   without one.
2. **Fewer remaining blockers on other items** — issues that other
   Ready/Backlog items depend on should be done first (they unblock
   more work). Check whether any other project item lists this issue
   in its `blockedBy`.
3. **Labels** — prioritize `bug` or `critical` over feature work.
4. **Simplicity** — when all else is equal, prefer the smaller-scoped
   issue (shorter body, fewer acceptance criteria) to build momentum.

Present the **full ranked list** as a numbered table:

| #   | Issue | Title | Milestone | Labels | Why |
| --- | ----- | ----- | --------- | ------ | --- |

Highlight the top recommendation with a short explanation of why it
ranks first. Use `AskUserQuestion` to let the user pick:

- Options: the top 3–4 issues by title (e.g. "#42 — Add token refresh")
- The user can also type a different issue number.

## Step 4: Assign the issue

Get the current user's GitHub login:

```bash
gh api --method GET user --jq '.login'
```

Assign the chosen issue:

```bash
gh issue edit <N> --add-assignee '<LOGIN>'
```

Move the item to **In progress** on the project board:

```
gh api graphql -f query='
  mutation {
    updateProjectV2ItemFieldValue(input: {
      projectId: "<PROJECT_NODE_ID>"
      itemId: "<ITEM_ID>"
      fieldId: "<STATUS_FIELD_ID>"
      value: { singleSelectOptionId: "<IN_PROGRESS_OPTION_ID>" }
    }) {
      projectV2Item { id }
    }
  }
'
```

## Step 5: Check for repo-specific implementation requirements

Before handing off to the implement skill, check whether the target
repository has any custom skills or conventions that should feed into
implementation. Run these checks **in parallel**:

1. **Custom skills** — look for `.claude/commands/` in the repo root.
   List any skills whose description suggests they should be run before
   or during implementation (e.g. a requirements-gathering skill, a
   scaffold skill, a spec skill). Read their descriptions to understand
   what they do.

2. **CLAUDE.md** — read the repo's `CLAUDE.md` (if it exists) for
   implementation conventions, required tools, or workflow notes that
   should be passed as additional requirements.

3. **Rules** — scan `.claude/rules/` for any rule files that mention
   implementation patterns, required steps, or constraints.

Collect anything relevant into a short `additional requirements` string
that will be passed to the implement skill.

## Step 6: Start implementation

Invoke the implement skill with the chosen issue number and any
additional requirements discovered in Step 5:

```
/helpers:implement <N> <additional requirements>
```
