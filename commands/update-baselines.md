---
description: Fetch visual baseline artifacts from a failed CI run, update local baselines, commit, and push
---

Download updated visual baseline screenshots from the latest failed CI
run on the current PR, replace local baselines, commit, and push.

## Step 1: Verify PR context

Confirm a PR exists for the current branch:

```bash
gh pr view <PR_NUMBER> --json number,headRefName,headRefOid
```

If no PR is found, tell the user and stop.

## Step 2: Find the failed run with artifacts

List workflow runs for the PR's head SHA and find the most recent
failed run that produced artifacts:

```bash
gh run list --branch '<headRefName>' --status failure --limit 5 --json databaseId,name,conclusion,createdAt
```

For each failed run, check for artifacts:

```bash
gh api repos/{owner}/{repo}/actions/runs/<RUN_ID>/artifacts --jq '.artifacts[] | {id, name, size_in_bytes, expired}'
```

Filter to artifacts whose name suggests visual baselines or test
results (e.g. contains `screenshot`, `snapshot`, `visual`, `baseline`,
`test-results`, `playwright-report`, `diff`). If no artifact names
match these heuristics, list all available artifacts and let the user
pick.

If multiple failed runs have matching artifacts, pick the most recent.

If no artifacts are found on any failed run, tell the user and stop.

## Step 3: Download artifacts

Download into a temporary directory:

```bash
TMPDIR=$(mktemp -d)
gh run download <RUN_ID> -n '<artifact-name>' -D "$TMPDIR"
```

List what was downloaded:

```bash
find "$TMPDIR" -type f | head -50
```

## Step 4: Discover baseline location

Determine where visual baselines live in the project. Check in order:

1. **CLAUDE.md** — look for a section mentioning baselines, snapshots,
   or screenshots that documents the path.
2. **Test config files** — read `playwright.config.ts`,
   `playwright.config.js`, `cypress.config.ts`, or similar. Look for
   `snapshotDir`, `snapshotPathTemplate`, `screenshotsFolder`, or
   equivalent settings.
3. **Directory search** — find existing baseline directories:

   ```bash
   find . -type d \( -name '*snapshots*' -o -name '*screenshots*' -o -name '*baselines*' \) | grep -v node_modules | grep -v .claude | head -10
   ```

4. **Match by filename** — compare filenames from the downloaded
   artifact against existing files in the repo:

   ```bash
   # For each .png in the artifact, find matching files in the repo
   find . -name '<artifact-filename>' -not -path '*/node_modules/*' -not -path '*/.claude/*'
   ```

If the baseline location cannot be determined, ask the user.

## Step 5: Copy updated baselines

The artifact typically contains actual/updated screenshots (not diffs).
Identify which files are the updated baselines:

- Files named `*-actual.png` or in an `actual/` subdirectory are the
  new baselines — strip the `-actual` suffix or flatten the path when
  copying.
- Files named `*-diff.png` or `*-expected.png` are comparison outputs
  — skip these.
- If the naming convention is unclear, show the artifact structure and
  ask the user which files to use.

Copy each updated baseline to its matching location in the project.
Report a summary:

```
Updated 3 baselines:
  tests/snapshots/header.png
  tests/snapshots/footer.png
  tests/snapshots/sidebar.png
```

## Step 6: Commit and push

Stage, commit, and push the updated baselines:

```bash
git add -A
git status
```

Use `AskUserQuestion` to confirm:

- Question: "Commit and push updated baselines?"
- Options: "Yes, push" / "Review changes first" / "Cancel"

If **review**: run `git diff --cached --stat` and ask again.

On confirmation:

```bash
git commit -m 'test: update visual baselines'
git push --force-with-lease
```

Clean up:

```bash
rm -rf "$TMPDIR"
```

Report the push result and remind the user to check the new CI run.

## Rules

- Never overwrite files without showing the user what will change.
- If the artifact structure doesn't match expectations, show it and ask
  rather than guessing.
- Use `--force-with-lease` for push, never `--force`.
- No attribution in commit messages.
