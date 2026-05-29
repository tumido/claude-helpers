---
description: Review and update CLAUDE.md and .claude/rules/ to match current codebase state
---

Review this conversation session and update project documentation so Claude never works with stale context.

## Step 1: Gather current state

Read these files (skip any that don't exist):

1. Project manifest (`package.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`, etc.) — for dependencies and scripts
2. Top-level directory listing — for file structure changes
3. Schema files (`prisma/schema.prisma`, `db/schema.*`, etc.) — for data model changes
4. `CLAUDE.md`
5. All files in `.claude/rules/`

## Step 2: Check CLAUDE.md

Compare documented state against actual project state. Update if any of these drifted:

- **Stack** — new or removed dependencies that change the tech stack description
- **Commands** — new, renamed, or removed scripts/commands
- **File structure** — new top-level directories or reorganized layout
- **Safety rules** — new dangerous operations discovered during the session

Rules for updates:
- Keep it under 80 lines
- Remove stale entries — don't comment them out or add "deprecated" notes
- Don't add what's derivable from reading code or config files
- Preserve user-added custom sections

## Step 3: Check .claude/rules/

For each existing rule file:
- Verify the patterns described still match actual code
- Update examples if implementations changed
- Check that `paths:` frontmatter globs still match actual file locations
- Remove rules for patterns that no longer exist in the codebase

Look for new patterns introduced in this session:
- New directory structures with conventions worth documenting
- New libraries/frameworks with specific usage patterns
- New integration patterns that are non-obvious

Create new rule files only when a genuine, reusable pattern was established. Don't document one-off implementations.

## Step 4: Clean up

- Remove any `.claude/rules/` files whose subject area no longer exists in the project
- Check for redundancy — if two rule files cover overlapping ground, merge them
- Verify all rule files have correct `paths:` frontmatter

## Step 5: Report

List what changed in 2-3 lines. The user can read the diffs — don't explain the content of changes, just name which files were updated/created/removed and why.
