---
description: Fetch visual baseline artifacts from a failed CI run, update local baselines, commit, and push
---

Run the update-baselines script:

```bash
"$CLAUDE_HELPERS_DIR/scripts/update-baselines.sh"
```

The script automatically:
1. Verifies a PR exists for the current branch
2. Finds the most recent failed CI run with visual testing artifacts
3. Downloads matching artifacts (screenshot, snapshot, baseline, etc.)
4. Discovers where baselines live in the project (from test configs or existing directories)
5. Copies updated baselines, stripping `-actual` suffixes and skipping diff/expected files

Pass `--run-id <ID>` to target a specific run.

If the script exits with an error it cannot auto-resolve (e.g. no baseline directory found), help the user by inspecting the artifact contents and project structure to determine the correct destination, then re-run or copy manually.

## After the script completes

Stage and review the changes:

```bash
git add -A
git diff --cached --stat
```

Use `AskUserQuestion` to confirm:

- Question: "Commit and push updated baselines?"
- Options: "Yes, push" / "Review changes first" / "Cancel"

If **review**: run `git diff --cached` and ask again.

On confirmation:

```bash
git commit -m 'test: update visual baselines'
git push --force-with-lease
```

Report the push result and remind the user to check the new CI run.

## Rules

- Never overwrite files without showing the user what will change.
- If the artifact structure doesn't match expectations, show it and ask rather than guessing.
- Use `--force-with-lease` for push, never `--force`.
- No attribution in commit messages.
