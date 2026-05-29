---
description: Use --method GET for REST reads and plugin scripts for GraphQL reads to auto-allow without prompts
---

# GitHub API read convention

## REST reads

Always include `--method GET` explicitly — even though GET is the
default. This lets the permission system auto-allow reads while still
prompting for writes.

```bash
# Reads — auto-allowed
gh api --method GET repos/owner/repo/pulls
gh api --method GET /repos/owner/repo/issues/42 --jq '.title'

# Writes — prompted for confirmation
gh api -X POST repos/owner/repo/issues -f title="Bug report"
gh api -X PATCH repos/owner/repo/issues/42 -f state=closed
```

## GraphQL reads

`--method GET` breaks GraphQL, so use the read-only wrapper scripts
from this plugin's `scripts/` directory instead. They are auto-allowed
via permissions, output JSON, and can be piped through `jq`.

Scripts are at `$CLAUDE_HELPERS_DIR/scripts/` (env var set in
`~/.claude/settings.json`).

| Script | Usage | Purpose |
|--------|-------|---------|
| `gh-project-fields.sh` | `<owner> <project-number>` | Project ID, Status field ID, option IDs |
| `gh-project-items.sh` | `<owner> <project-number>` | All project items with status, labels, milestones, assignees, blockedBy (auto-paginates) |
| `gh-issue-deps.sh` | `<owner> <repo> <number...>` | blockedBy + closedByPRs for one or more issues |
| `gh-search-issues.sh` | `<query>` | Search issues by query string |

```bash
# Examples — auto-allowed
bash "$CLAUDE_HELPERS_DIR/scripts/gh-project-fields.sh" redhat-et 31
bash "$CLAUDE_HELPERS_DIR/scripts/gh-project-items.sh" redhat-et 31 | jq '[.[] | select(.status == "Ready")]'
bash "$CLAUDE_HELPERS_DIR/scripts/gh-issue-deps.sh" redhat-et hermes 158 160 164
bash "$CLAUDE_HELPERS_DIR/scripts/gh-search-issues.sh" 'repo:redhat-et/hermes is:issue is:open #158'
```

GraphQL **mutations** (project status updates, addBlockedBy, etc.)
must still use raw `gh api graphql` and will be prompted for
confirmation.