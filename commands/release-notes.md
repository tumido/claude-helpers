---
description: Generate release notes from merged PRs and create a draft GitHub release
args: <base>..<head> — git revision range (tags, commits, or branches)
---

Collect merged PRs in a revision range, analyze their content, and
produce feature-oriented release notes as a draft GitHub release.

## Step 1: Determine the revision range

If no argument is provided, list recent tags and ask the user to
pick a range. Validate both ends resolve with `git rev-parse`.

## Step 2: Collect and filter PRs

Extract merged PR numbers from `git log` in the range (squash-merge
subjects contain `(#N)`, merge commits say `Merge pull request #N`).

Filter out dependency-update PRs — those authored by renovate,
dependabot, or similar bots, or with titles starting with
`chore(deps):`, `build(deps):`, `Bump `.

Fetch full PR details (`title`, `body`, `labels`, `author`) for all
remaining PRs via `gh pr view`.

## Step 3: Gather release metadata

Use `AskUserQuestion` to collect:

- **Version tag** — suggest the next version based on the latest
  existing tag
- **Release title**
- **Framing context** — options: "First release" / "Feature release"
  / "Patch/bugfix release" / custom text

## Step 4: Write release notes

Analyze all PR titles and bodies together and produce release notes:

- **Feature-oriented, not PR-oriented** — group by what was built,
  not by individual PRs. Multiple PRs contributing to one feature
  become one description.
- **Rich with detail** drawn from PR bodies — architecture, design
  rationale, implementation specifics.
- **Organized into sections** by subsystem or capability using `##`
  headers.
- **No PR numbers** anywhere in the text.
- **Past tense** ("Added", "Fixed", "Improved").
- Formatted as a GitHub release body in markdown.

End with:

1. **Contributors** — all unique PR authors as `@username`,
   alphabetical, equal credit, no PR counts.
2. **Full changelog** — link to a GitHub PR search filtered to the
   date range of the revision range
   (`<repo-url>/pulls?q=is:pr+is:merged+merged:<base-date>..<head-date>`).

## Step 5: Create draft release

Present the notes to the user for review. On confirmation, create
via `gh release create --draft`, targeting the resolved commit SHA
of `<head>`.

## Rules

- Always create as `--draft`.
- No PR numbers in release note text.
- No dependency-update PRs.
- Group by feature, not by PR.
- Equal credit in Contributors.
