# claude-helpers

Personal Claude Code plugin — project bootstrap, doc upkeep, issue
tracker maintenance, and GitHub API permission helpers.

## Install

### 1. Register the plugin marketplace

```bash
claude plugins:add github.com/tumido/claude-helpers
```

### 2. Enable the plugin

```bash
claude plugins:enable helpers@claude-helpers
```

### 3. Set the environment variable

Add to the `env` block in `~/.claude/settings.json`, pointing to
wherever the plugin was cloned:

```json
"env": {
  "CLAUDE_HELPERS_DIR": "/path/to/claude-helpers"
}
```

Skills and rules reference scripts via `$CLAUDE_HELPERS_DIR/scripts/`.

### 4. Add permissions for GitHub API read scripts

Add to `permissions.allow` in `~/.claude/settings.json`:

```json
"Bash(bash /path/to/claude-helpers/scripts/gh-project-fields.sh *)",
"Bash(bash /path/to/claude-helpers/scripts/gh-project-items.sh *)",
"Bash(bash /path/to/claude-helpers/scripts/gh-issue-deps.sh *)",
"Bash(bash /path/to/claude-helpers/scripts/gh-search-issues.sh *)",
"Bash(gh api --method GET *)",
"Bash(gh api -X GET *)"
```

Replace `/path/to/claude-helpers` with the actual location in steps
3 and 4.

## What's included

### Skills (`/helpers:*`)

| Skill | Purpose |
|-------|---------|
| `next` | Pick the next issue from the project board and start working |
| `implement` | Fetch a GitHub issue and implement it |
| `board-tidy` | Move unblocked issues to Ready, flag stale statuses |
| `issue-sync` | Create issues, set blocking relationships, update tracking |
| `issue-audit` | Audit open issues/PRs for gaps and missing tasks |
| `ship` | Draft a commit message or PR from current git state |
| `done` | Exit the current worktree |
| `bootstrap` | Set up CLAUDE.md, rules, and commands for a project |
| `remember` | Update CLAUDE.md and rules to match codebase state |

### Rules

| Rule | Purpose |
|------|---------|
| `docs-upkeep` | Silently update CLAUDE.md/rules after implementation changes |
| `gh-api-reads` | Use `--method GET` for REST and wrapper scripts for GraphQL reads |

### Scripts (`scripts/`)

Read-only GitHub GraphQL wrappers with flattened JSON output:

| Script | Usage | Purpose |
|--------|-------|---------|
| `gh-project-fields.sh` | `<owner> <project-number>` | Project ID, Status field ID, option IDs |
| `gh-project-items.sh` | `<owner> <project-number>` | All items with status, labels, milestones, assignees, blockedBy (auto-paginates) |
| `gh-issue-deps.sh` | `<owner> <repo> <number...>` | blockedBy + closedByPRs for one or more issues |
| `gh-search-issues.sh` | `<query>` | Search issues by query string |

See `rules/gh-api-reads.md` for the read-only convention these
scripts enforce.
