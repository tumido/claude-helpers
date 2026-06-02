---
description: Pick the next issue to work on from the project board and start implementing it
---

Find Ready items on the GitHub project board, recommend the best one
to work on next, assign it on confirmation, and kick off implementation.

`<HELPERS_DIR>` appears in commands below. Before running any
script, run `printenv CLAUDE_HELPERS_DIR` to get the absolute path,
then substitute that path for every `<HELPERS_DIR>` in the commands
you execute.

## Step 1: Gather project metadata

Run all three of these **in parallel** (single message, multiple tool
calls):

1. **Repository** — `gh repo view --json owner,name`

2. **Project fields** — find the project number, then fetch field IDs:

   ```bash
   gh project list --owner <OWNER> --format json \
     | jq '.projects[] | select(.title | test("<keyword>"; "i")) | {number, title}'
   ```

   Use the repo name or a known keyword to filter. Then:

   ```bash
   bash <HELPERS_DIR>/scripts/gh-project-fields.sh <OWNER> <N>
   ```

   Save: project node ID, Status field ID, and option IDs for each
   status (Backlog, Ready, In progress, In review, Done).

3. **Milestones** — `gh api --method GET repos/:owner/:repo/milestones`
   to identify which milestone(s) are active.

## Step 2: Check existing work-in-progress

Get the current user's login and check for items already assigned to
them:

```bash
gh api --method GET user --jq '.login'
```

```bash
bash <HELPERS_DIR>/scripts/gh-project-items.sh <OWNER> <N> --no-body \
  | jq --arg me '<LOGIN>' '[.[] | select(.state == "OPEN" and (.assignees | any(. == $me)) and .status == "In progress")]'
```

If the user has in-progress items, present them and use
`AskUserQuestion`:

- "Continue existing work on #N?"
- "Pick something new"

If they choose to continue, invoke `/helpers:implement <N>` and stop.

## Step 3: Query and rank Ready items

Fetch all project items (without bodies) and compute ranking data in
a single jq pipeline:

```bash
bash <HELPERS_DIR>/scripts/gh-project-items.sh <OWNER> <N> --no-body \
  | jq '
    . as $all |
    [.[] | select(
      .status == "Ready" and
      .state == "OPEN" and
      (.assignees | length == 0) and
      .parent == null
    )] |
    map(. as $item | . + {
      blocks_count: [$all[] | select(
        .state == "OPEN" and
        (.blocked_by[]? | .number) == $item.number
      )] | length
    })
  '
```

This produces a list of Ready items, each with a `blocks_count`
showing how many other open items depend on it.

## Step 4: Score and recommend

Score each candidate using these weights:

| Criterion | Points | Rationale |
|-----------|--------|-----------|
| In active milestone | +10 | Milestone work has a deadline |
| Per open item it blocks | +5 | Unblocks more downstream work |
| `bug` or `critical` label | +3 | Defects before features |

Sort descending by total score. Present the **full ranked list** as
a numbered table:

| # | Issue | Title | Score | Milestone | Labels | Why |
|---|-------|-------|-------|-----------|--------|-----|

Highlight the top recommendation with a short explanation of why it
ranks first. Use `AskUserQuestion` to let the user pick:

- Options: the top 3–4 issues by title (e.g. "#42 — Add token refresh")
- The user can also type a different issue number.

## Step 5: Assign the issue

Assign the chosen issue to the current user:

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

## Step 6: Check for repo-specific implementation requirements

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

## Step 7: Start implementation

Invoke the implement skill with the chosen issue number and any
additional requirements discovered in Step 6:

```
/helpers:implement <N> <additional requirements>
```
