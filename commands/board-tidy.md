---
description: Tidy the GitHub project board — move unblocked issues to Ready, flag stale statuses
---

Maintain the GitHub project board. Move unblocked items from Backlog
to Ready, and flag items whose status doesn't match their actual
state (e.g., "In progress" but the issue is closed).

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

## Step 2: Query all project items

Fetch every item (auto-paginates, flattened output):

```bash
bash $CLAUDE_HELPERS_DIR/scripts/gh-project-items.sh <OWNER> <N>
```

Output fields per item: `item_id`, `status`, `status_option_id`,
`number`, `title`, `state`, `labels`, `milestone`, `parent`,
`assignees`, `blocked_by`, `blocked_by_count`.

## Step 3: Identify items to move to Ready

Filter for items that meet ALL of these criteria:

- Current status is **Backlog**
- `blockedBy.totalCount == 0` (no blocking issues)
- `parent == null` (not a sub-issue — sub-issues inherit status from
  parent)
- Issue is in the **active milestone** (skip bot issues like Renovate
  Dependency Dashboard, and exploration/post-MVP items without a
  milestone)
- Issue state is **OPEN** (not closed)

## Step 4: Identify stale statuses

Flag items where the board status doesn't match reality:

- **Status is "In progress" or "In review" but the issue is closed**
  — should be Done
- **Status is "Backlog" or "Ready" but the issue is closed** — should
  be Done
- **Status is "In progress" but all blocking issues are still open**
  — might be premature, flag for review
- **Status is "Ready" but the issue now has open blockers** — should
  move back to Backlog (a new dependency was added after it was marked
  Ready)

## Step 5: Confirm with user

Present two lists:

1. **Move to Ready** — items that qualify, with issue number and title
2. **Stale statuses** — items with mismatched status, with current vs
   suggested status

Ask the user to confirm before making changes. They may want to
exclude specific items.

## Step 6: Apply changes

For each approved status change, update the project item:

```
gh api graphql -f query='
  mutation {
    updateProjectV2ItemFieldValue(input: {
      projectId: "<PROJECT_NODE_ID>"
      itemId: "<ITEM_ID>"
      fieldId: "<STATUS_FIELD_ID>"
      value: { singleSelectOptionId: "<TARGET_OPTION_ID>" }
    }) {
      projectV2Item { id }
    }
  }
'
```

## Step 7: Report

Summary table:

| Issue | Title | Previous status | New status |
|-------|-------|-----------------|------------|

Note any items left in Backlog that have 0 blockers but were excluded
(non-milestone, sub-issues, bot issues) with the reason.
