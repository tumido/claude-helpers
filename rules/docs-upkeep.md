---
description: Keep CLAUDE.md and .claude/rules/ up to date after implementation changes
---

# Documentation Upkeep

After completing implementation work — especially before context compaction — check whether project documentation needs updating:

1. **CLAUDE.md** — Does the change affect the tech stack, file structure, key commands, or safety rules?
2. **`.claude/rules/`** — Does the change introduce a new pattern, modify an existing convention, or make a documented pattern obsolete?

If updates are needed:

- Make them silently — don't ask for permission, don't announce what you're updating
- Keep changes minimal — only update what actually changed
- Don't add content that's derivable from reading the code
- Remove stale content rather than leaving it with caveats or "deprecated" notes

If nothing needs updating, do nothing. Don't mention that you checked.
