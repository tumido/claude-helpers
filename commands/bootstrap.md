---
description: Bootstrap a project with Claude configuration — CLAUDE.md, scoped rules, and commands
---

Bootstrap this project for optimal Claude Code usage. Follow each step in order.

## Step 1: Auto-detect project characteristics

Scan the project root and gather:

- **Manifest files**: `package.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`, `requirements.txt`, `Gemfile`, `pom.xml`, `build.gradle`, `*.csproj`, `Makefile`, `CMakeLists.txt`, `flake.nix`, `deno.json`
- **Existing Claude config**: `.claude/` directory, `CLAUDE.md`
- **Formatter/linter configs**: `.editorconfig`, `.prettierrc*`, `prettier.config.*`, `eslint.config.*`, `.eslintrc*`, `.rubocop.yml`, `.golangci.yml`, `rustfmt.toml`, `pyproject.toml [tool.ruff]`, `biome.json`
- **Infrastructure**: `docker-compose.yml`, `Dockerfile`, `.github/`, `.gitlab-ci.yml`
- **Git remote URL** for project name inference
- **README.md** for project description
- **Directory structure**: top-level directories, `src/`, `lib/`, `app/`, `cmd/`, `pkg/`, `internal/`, `tests/`, `spec/`
- **Schema files**: `prisma/schema.prisma`, `db/schema.*`, `*.graphql`, OpenAPI specs
- **Lockfiles**: to confirm package manager (`package-lock.json` → npm, `yarn.lock` → yarn, `pnpm-lock.yaml` → pnpm, `go.sum`, `Cargo.lock`, `poetry.lock`, `Gemfile.lock`)

**For the parallel-instances rule**, also detect:
- **Dependency directories**: `node_modules/`, `vendor/`, `.venv/`, `target/`, `_build/`, `deps/`, `__pycache__/`, `.gradle/`
- **Environment files**: `.env`, `.env.local`, `.env.development`, `.env.development.local`
- **Dev server command and default port**: from scripts in manifest (e.g., `"dev": "next dev"` on port 3000, `"serve": "go run ./cmd/server"` on port 8080)
- **Build output directories**: `.next/`, `dist/`, `build/`, `out/`, `target/`, `_build/`
- **Lint/type-check commands**: from scripts or Makefile targets
- **Test framework and command**: from scripts, test config files, or Makefile

If a `CLAUDE.md` or `.claude/rules/` already exist, read them — you'll update rather than overwrite.

## Step 2: Ask the user to confirm and fill gaps

Use AskUserQuestion to gather what you couldn't auto-detect. Ask in batches of 2-4 questions max. Only ask what's missing — don't re-ask what config files already answer.

**Essential to establish:**

1. **Project identity**: Name, one-line description, primary purpose — confirm what you inferred from README/manifest
2. **Code style** (only if no formatter config found): Naming conventions for files, functions, variables, constants. Indentation, quotes, semicolons.
3. **Key commands**: Dev server, build, test, lint, type-check, format, deploy. Confirm what you found in scripts/Makefile.
4. **Safety rules**: Destructive commands that require explicit permission — database resets, force pushes, production deploys, cache/data wipes, secret rotation. Ask: "Are there any commands that should NEVER be run without your explicit go-ahead?"
5. **UI language** (only for user-facing apps): Is the UI in a different language than code/comments?

**Skip if obvious from config.** If `package.json` has `"lint": "eslint ."`, don't ask "what's your lint command?"

## Step 3: Generate CLAUDE.md

Create (or update) `CLAUDE.md` at the project root. Structure:

```markdown
# <Project Name>

<One-line description>

## Stack

<One bullet per core technology — language, framework, database, key libraries>

## Code Style

<Naming conventions, formatting rules — ONLY what's NOT enforced by config files>
<If .prettierrc or equivalent handles formatting, just say "Formatting enforced by <tool> — see <config file>">

## Commands

| Command | Purpose |
|---------|---------|
| `...`   | ...     |

## File Structure

<Brief overview — what goes where. 5-15 lines max.>

## Safety Rules

<Commands/operations that require explicit user permission. Be specific.>
```

**Hard limit: under 80 lines.** Only include what Claude needs that isn't derivable from reading code or config files. If the project already has a CLAUDE.md, preserve any user-added sections and update only what's stale.

## Step 4: Create scoped rules

Create `.claude/rules/` directory if it doesn't exist. Add rule files ONLY for patterns the project actually uses. Each file MUST have frontmatter:

```yaml
---
description: <what this rule covers>
paths:
  - <glob pattern matching files where this rule applies>
---
```

**Detect and create rules for these areas (only if they exist in the project):**

- **Component patterns** (UI framework detected) — paths: `components/**`, `src/components/**`
- **Data fetching / services** — paths: `lib/services/**`, `src/api/**`, `internal/service/**`
- **Database / ORM** — paths: `prisma/**`, `db/**`, `migrations/**`, `models/**`
- **Auth** (auth library detected) — paths: `lib/auth*`, `src/auth/**`, `middleware*`
- **API routes** — paths: `app/api/**`, `routes/**`, `cmd/server/**`, `handlers/**`
- **Testing** (test framework detected) — paths: `tests/**`, `**/*.test.*`, `**/*_test.*`, `spec/**`
- **Security** (encryption, secrets, validators) — paths: `**/encrypt*`, `**/valid*`, `.env*`

**Each rule file should be 20-60 lines.** Include only:
- Which patterns/conventions to follow in this area
- Key do's and don'ts
- A short code example if the pattern is non-obvious

**Don't create speculative rules.** Only document patterns that already exist in the codebase. Read actual source files to understand the conventions before writing rules.

## Step 5: Generate parallel-instances rule

**Always create this rule.** It enables safe parallel work with git worktrees. Use the project details detected in Step 1 to fill in all project-specific values.

Ask the user:

1. **Merge preference**: "When parallel worktree agents complete their work, should the result be merged into the base branch automatically, or kept as a feature branch for you to review first?" — offer choices: "Merge (for incremental changes later work depends on)", "Keep as feature branch (for independent changes / separate PRs)", "Ask me each time"

Generate `.claude/rules/parallel-instances.md` with the following structure. Replace all `<placeholders>` with actual project-specific values from Step 1.

```markdown
---
description: Rules for parallel Claude instances working in git worktrees
---

# Parallel Instances

Multiple Claude instances may work on this codebase simultaneously. Follow these rules to avoid conflicts.

## Worktree isolation

When told you are working in parallel, operate in a git worktree — never edit files in the main working tree if another instance may be active there. Run `git worktree list` to see active worktrees. When spawning agents via the Agent tool, use `isolation: "worktree"`.

When spawning worktree agents, use `mode: "acceptEdits"`. Other modes (`bypassPermissions`, `auto`, `default`) do not reliably grant Write/Edit tool access in worktree-isolated agents.

## Worktree environment setup

Worktrees only get tracked (committed) files. Gitignored files like `<dependency_dir>/`, `<env_files>`, and `<build_output_dir>/` are missing and must be set up before doing any work.

**Run these steps FIRST in every new worktree, before reading files or writing code.**

Each step must be a separate, simple Bash call — compound commands with variable assignments (e.g., `MAIN_TREE=$(...)`) will be denied by the permission system since it matches on the first word of the command.

**Step 1:** Find the main tree path:

```bash
git worktree list --porcelain
```

Read the first line to get the main tree path.

**Step 2:** Copy <dependency_dir> (copy, not symlink — workers may add dependencies):

```bash
cp -a /path/to/main/tree/<dependency_dir> ./<dependency_dir>
```

<If multiple dependency dirs exist (e.g., node_modules + .next), list each copy command>

**Step 3:** Copy environment file:

```bash
cp /path/to/main/tree/<env_file> ./<env_file>
```

<List the specific env files detected: .env, .env.local, etc.>

If `cp` is denied for `.env` (built-in safety rule may block copying secret files): use the `Read` tool to read the main tree's env file, then use the `Write` tool to create it in the worktree with the same content.

**Step 4:** Create feature branch:

```bash
git checkout -b feat/<area>-<what>
```

If any of steps 1-3 fail, stop and report the error — nothing else will work.

## Permissions

The worktree gets `.claude/settings.local.json` from the **committed** state at worktree creation time. If permissions have been updated but not committed, the worktree will have stale permissions and tool calls will be denied.

**Before spawning worktree agents:** ensure all changes to `.claude/settings.local.json` are committed on the base branch.

## Base branch

Do NOT assume `main` or `master` is the base branch. Determine the current base branch by checking which branch the main tree is on:

```bash
git -C /path/to/main/tree branch --show-current
```

Use that branch as the merge target for worktree feature branches.

## Dev servers

When working directly in the main tree (interactive session with the user), dev servers are managed externally — never run `<dev_command>`. Ask the user to start them if needed.

When working in an **isolated worktree** (parallel background work), you may start the dev server yourself on any available port. Pick a port that doesn't conflict with the main tree (<default_port>) or other worktrees.

Start worktree dev server with: `<port_env_var>=<port> <dev_command>`

Run the dev server in the background using Bash with `run_in_background: true`. Then verify it started as a separate command:

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:<port>/
```

**Important:** Use the Bash tool's `run_in_background` parameter — do not use `&` or `nohup`. A regular Bash call will hang waiting for the server to exit.

## Build coordination

In a worktree, `<build_output_dir>/` directories are isolated. In a shared tree, only one instance should build at a time. Always run `<lint_command>` before committing.

## Branch conventions

Use `feat/<area>-<what>` or `fix/<area>-<what>`. Each parallel instance must be on its own branch.

## Merging worktree work back to base

You cannot `git checkout <base-branch>` from a worktree — the base branch is checked out in the main tree. Instead:

1. Determine the base branch: `git -C /path/to/main/tree branch --show-current`
2. Commit and rebase onto the base branch from the worktree: `git rebase <base-branch>`
3. Resolve any conflicts, `<lint_command>` to verify
4. Merge from the **main repo**: `git -C /path/to/main/tree merge <branch> --ff-only`
5. Stop any worktree dev servers, then exit and remove the worktree via `ExitWorktree`

<If user chose "Ask me each time" or "Keep as feature branch":>
**Agents must NOT merge into the base branch themselves.** Commit on the feature branch only. The parent session decides whether to merge or keep a separate branch.
<If user chose "Merge":>
**Agents may merge via --ff-only** after rebasing and passing lint. If --ff-only fails, stop and report — do not force merge.

### Parent session merge checklist

When the parent session receives a completed worktree agent result:

1. **Always use `-C` with the main tree path** for git commands — your shell CWD may be stale after worktree removal:

   ```bash
   git -C /path/to/main/tree merge feat/<branch> --no-edit
   ```

2. **Verify the merge landed** — check the commit is on the base branch:

   ```bash
   git -C /path/to/main/tree log --oneline -3
   ```

3. **Only then clean up** — remove the worktree and delete the branch:

   ```bash
   git -C /path/to/main/tree worktree remove .claude/worktrees/<name> --force
   git -C /path/to/main/tree branch -d feat/<branch>
   ```

If keeping as a separate feature branch, skip steps 1-2 and only remove the worktree (keep the branch). Never delete a feature branch before confirming its commits are on the base branch.

## File edit safety (shared tree only)

If not in a worktree, run `git status` before editing — if a file is already modified, another instance may own it. Commit frequently to reduce conflict windows.
```

**Adapt this template to the project:**
- Replace `<dependency_dir>` with the actual dependency directory (e.g., `node_modules`, `vendor`, `.venv`, `target`)
- Replace `<env_file>` / `<env_files>` with actual env files found (e.g., `.env`, `.env.local`)
- Replace `<build_output_dir>` with actual build output (e.g., `.next`, `dist`, `target`)
- Replace `<dev_command>` with actual dev server command (e.g., `npm run dev`, `go run ./cmd/server`, `cargo run`)
- Replace `<default_port>` with the project's default dev port (e.g., 3000, 8080)
- Replace `<port_env_var>` with the right env var (e.g., `PORT`, `ADDR`, `LISTEN`)
- Replace `<lint_command>` with actual lint command (e.g., `npm run lint`, `make lint`, `cargo clippy`)
- If the project has no dev server (e.g., a library or CLI tool), omit the "Dev servers" section entirely
- If the project uses a testing tool with browser sessions (e.g., Playwright), add a "Verifying UI changes" section recommending `playwright-parallel` MCP or equivalent isolated browser sessions — never the user's main browser session
- Remove any sections that don't apply (e.g., no dev server for a library)

## Step 6: Verify and report

1. List all files created or updated
2. Show a brief summary of what was set up
3. Remind the user to run `/remember` after making significant changes to keep config current
4. If there are areas you couldn't fully document (e.g., complex auth flow you didn't fully read), mention them so the user can fill in details later
