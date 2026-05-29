---
description: Audit open issues and PRs against the codebase to find missing tasks, gaps, and issues that need breaking down
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

## Step 4: Identify gaps

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

## Step 5: Flag coarse issues

Identify issues that are too broad to implement as a single unit.
An issue is too coarse when it:

- Spans more than 2-3 independent implementation units
- Contains acceptance criteria that belong to different components
- Would take more than a week of focused work
- Mixes scaffolding with feature logic

## Step 6: Report

Present findings to the user organized as:

1. **Current state** — table of areas (frontend, backend, infra, etc.)
   with implementation status (done / partial / not started)
2. **PR coverage** — what each open PR delivers and what it doesn't
3. **Missing tasks** — numbered list of concrete gaps with brief
   descriptions, grouped by area. Note which existing issue each gap
   relates to.
4. **Issues to break down** — table of coarse issues with suggested
   subtask splits
5. **Critical path** — what blocks what, what can start now

Do NOT create or modify any issues. This is analysis only. The user
decides what to act on.
