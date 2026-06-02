---
description: Create missing GitHub issues, set blocking relationships, update existing issues, and refresh the tracking issue
---

Write changes to the GitHub issue tracker: create new issues, wire
blocking dependencies, update existing issues with comments, and
refresh the pinned tracking issue. Run `/helpers:issue-audit` first
to identify what needs doing.

`<HELPERS_DIR>` appears in commands below. Before running any
script, run `printenv CLAUDE_HELPERS_DIR` to get the absolute path,
then substitute that path for every `<HELPERS_DIR>` in the commands
you execute.

## Step 1: Gather repo and project metadata

1. **Repository** — `gh repo view --json owner,name` for owner/repo.

2. **Milestones** — `gh api --method GET repos/:owner/:repo/milestones`
   for milestone names and numeric IDs.

3. **Labels** — `gh label list --limit 100 --json name` to know what
   exists. Do not create labels — use only existing ones.

4. **GitHub Project** — find the project number and fetch Status field
   option IDs:

   ```bash
   gh project list --owner <OWNER> --format json
   bash <HELPERS_DIR>/scripts/gh-project-fields.sh <OWNER> <N>
   ```

## Step 2: Confirm scope with user

Before creating anything, present the full list of issues you intend
to create and existing issues you intend to modify. Include for each:

- Title, labels, milestone
- Which existing issues it relates to or blocks
- For existing issue updates: what the comment will say

Get explicit approval before proceeding.

## Step 3: Create new issues

For each approved issue:

```bash
gh issue create \
  --title "<title>" \
  --label "<label1>,<label2>" \
  --milestone "<milestone name>" \
  --body "$(cat <<'EOF'
## Description

<description>

## Acceptance Criteria

- [ ] <criterion>

## Dependencies

- #<N> -- <title>

## Architecture References

- <relevant ADRs or docs>
EOF
)"
```

After creation, add to the GitHub Project:

```bash
gh project item-add <PROJECT_NUMBER> \
  --owner <OWNER> \
  --url "https://github.com/<OWNER>/<REPO>/issues/<N>"
```

## Step 4: Set blocking relationships

Fetch GraphQL node IDs for every issue involved in a dependency:

```bash
bash <HELPERS_DIR>/scripts/gh-issue-deps.sh <OWNER> <REPO> <N1> <N2> ... \
  | jq -r '.data.repository.issue | "\(.number) \(.id)"'
```

Set each relationship with `addBlockedBy` (meaning: issue X is blocked
by issue Y — Y must finish before X can start):

```bash
gh api graphql -f query='
  mutation {
    addBlockedBy(input: {
      issueId: "<BLOCKED_ISSUE_NODE_ID>",
      blockingIssueId: "<BLOCKER_ISSUE_NODE_ID>"
    }) {
      clientMutationId
    }
  }
'
```

**Handle errors gracefully:**

- `"Target issue has already been taken"` — already exists, skip
- `"this dependency would create a cycle"` — reverse path exists,
  skip (do not force)

Batch into a bash script with associative arrays for the node ID map.
Run all mutations sequentially. Report each result.

## Step 5: Update existing issues

Add **comments** to existing issues for:

- **Updated dependencies** — reference new blocking issues by number
- **Scope clarification** — note what's now tracked separately
- **Current state** — what PRs cover and what remains
- **Implementation breakdown** — subtask suggestions for coarse issues

```bash
gh issue comment <N> --body "$(cat <<'EOF'
## <Section title>

<content>
EOF
)"
```

Reserve body edits for the tracking issue only.

## Step 6: Update the tracking issue

If a pinned tracking issue exists, rebuild its body to include:

1. All new issues in appropriate sections
2. Checkboxes reflecting current completion state
3. Open PRs section noting coverage
4. Updated Mermaid dependency graph (`graph LR`)
5. Updated critical path and parallel work streams

Use `gh issue edit <N> --body "$(cat <<'BODY' ... BODY)"` for the
full replacement.

## Step 7: Report

Produce a summary:

1. **Created** — table: issue number, title, labels
2. **Dependencies set** — table: blocked issue, blocking issue, result
3. **Updated** — table: issue number, what changed
4. **Tracking issue** — confirm updated or note why not
