---
description: Audit open issues and PRs against the codebase to find missing tasks, gaps, duplicates, overlapping work, dependencies, and issues that need breaking down
---

Read-only analysis of the issue tracker vs actual codebase state.
Produces a gap report — does not create or modify anything.

## Step 1: Gather context

1. **Open issues** — run
   `gh issue list --state open --limit 200 --json number,title,labels,body,milestone`
   and parse into a readable list grouped by milestone.

2. **Open PRs** — run
   `gh pr list --state open --limit 50 --json number,title,body,headRefName,files`
   to understand work in flight. For significant PRs, use
   `gh pr view <N> --json body,title,files` to read the full
   description and changed files.

3. **Closed issues in milestone** — run
   `gh issue list --state closed --limit 200 --milestone "<milestone>" --json number,title`
   to understand what's already been delivered.

4. **Pinned tracking issue** — ask the user which issue is the
   milestone tracker (if any). Read its body for the current plan
   structure.

## Step 2: Explore the codebase

Check what actually exists in the repo:

- **Source packages/modules** — directories, entry points, key files
- **Deployment** — Helm charts, Kubernetes manifests, Containerfiles,
  docker-compose, CI workflows
- **Tests** — feature files, test directories, coverage
- **Documentation** — ADRs, architecture docs, READMEs

Use Explore agents for broad searches across multiple areas. Focus on
understanding what's implemented vs what's just scaffolded vs what's
entirely missing.

## Step 3: Cross-reference

For each open issue in the milestone:

1. Read the issue body with
   `gh issue view <N> --json body,title,labels,milestone` to
   understand acceptance criteria.

2. Check whether code exists that addresses those criteria — look for
   relevant source files, endpoints, components, tests.

3. Check whether any open PR partially implements it.

4. Classify: **done** (code exists, criteria met), **partial** (some
   code, incomplete), **not started** (no code at all).

## Step 4: Analyze issue relationships

For each open issue, detect overlaps and relationships:

1. **Component overlap** — which issues touch the same files,
   components, or modules? Use grep to find which code areas each
   issue's acceptance criteria reference. Group issues by component
   clusters.

2. **Semantic similarity** — compare issue titles and descriptions.
   Flag potential duplicates when two issues describe similar work
   using different terminology (e.g., "Add auth middleware" vs
   "Implement request authentication").

3. **Dependency relationships** — identify when one issue assumes work
   from another (e.g., Issue A says "Gateway calls the Sandbox API"
   but Issue B covers "Create the Sandbox API"). Look for implicit
   parent-child relationships not captured in issue links.

4. **Acceptance criteria overlap** — check if multiple issues have
   acceptance criteria that cover the same deliverable. Flag when the
   same endpoint, test, or configuration would satisfy multiple
   issues.

5. **Scope conflicts** — find issues where the proposed implementation
   would conflict (e.g., both issues want to modify the same function
   in incompatible ways).

6. **Implicit dependencies** — detect when an issue's acceptance
   criteria reference entities (APIs, database tables, UI components)
   that don't exist yet and aren't owned by any other issue.

Build a relationship map showing:
- **Clusters** — issues grouped by component/area
- **Duplicates** — issue pairs with >70% description similarity
- **Depends-on** — issue A needs issue B's deliverable
- **Overlaps** — issues with shared acceptance criteria
- **Conflicts** — issues with incompatible changes to the same code

## Step 5: Identify gaps

Find concrete missing work:

- **Untracked tasks** — work assumed by existing issues but owned by
  no issue (e.g., an issue says "Gateway creates a SandboxClaim" but
  no issue covers adding the K8s client to the gateway)
- **Integration layers** — glue between components that nobody owns
  (database adapters, API proxy routes, SSE clients)
- **Scaffolding** — bootstrapping work needed before feature issues
  can start (new packages, new language projects, Containerfiles)
- **Cross-cutting** — shared infrastructure like retry strategies,
  error handling, state sync mechanisms
- **Missing from PRs** — things the open PRs don't cover that issues
  assume they will

## Step 6: Flag coarse issues

Identify issues that are too broad to implement as a single unit.
An issue is too coarse when it:

- Spans more than 2-3 independent implementation units
- Contains acceptance criteria that belong to different components
- Would take more than a week of focused work
- Mixes scaffolding with feature logic

## Step 7: Report

Present findings to the user organized as:

1. **Current state** — table of areas (frontend, backend, infra, etc.)
   with implementation status (done / partial / not started)

2. **Issue relationships** — the relationship map from Step 4:
   - **Component clusters** — issues grouped by which parts of the
     codebase they touch, showing overlap density
   - **Potential duplicates** — issue pairs that describe similar work
     (show title pairs and similarity reasoning)
   - **Dependency graph** — which issues depend on others (both
     explicit links and implicit dependencies detected from acceptance
     criteria)
   - **Overlapping acceptance criteria** — multiple issues claiming
     ownership of the same deliverable
   - **Scope conflicts** — issues proposing incompatible changes

3. **PR coverage** — what each open PR delivers and what it doesn't

4. **Missing tasks** — numbered list of concrete gaps with brief
   descriptions, grouped by area. Note which existing issue each gap
   relates to.

5. **Issues to break down** — table of coarse issues with suggested
   subtask splits

6. **Critical path** — what blocks what, what can start now, what
   should be sequenced to avoid conflicts

7. **Recommendations** — suggested actions:
   - Issues to merge/close as duplicates
   - Issues to split due to coarseness
   - Issues to resequence based on dependencies
   - Missing issues to create for unowned work

Do NOT create or modify any issues. This is analysis only. The user
decides what to act on.
