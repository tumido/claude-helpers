# Hermes Issue Audit Report
**Date**: 2026-08-19  
**Repository**: redhat-et/hermes  
**Branch**: main

## Executive Summary

- **Open issues**: 41 (5 no milestone, 20 v1.2, 10 v1.3, 6 v1.4)
- **Open PRs**: 9
- **Issues at ≥80% complete**: 4 (#1091, #875, #754, #755)
- **Issues blocked on infrastructure gaps**: 12 (eval harness cluster)
- **Issues ready to start**: 11
- **Issues requiring breakdown**: 6
- **Identified gaps not tracked by issues**: 10

**Milestone v1.2 health**: 20 issues, 8 in progress (PRs open), 4 near-complete, 8 not started. **At risk** due to eval harness infrastructure gap affecting 12 issues.

---

## 1. Current State by Area

| Area | Done | Partial | Not Started | Notes |
|------|------|---------|-------------|-------|
| **Core Infrastructure** | 100% | — | — | Gateway, session pod, token service, auth-proxy, database fully operational |
| **MCP Integrations** | 75% | Web Search (25%) | Slack (0%) | drive-mcp ✓, arxiv-mcp ✓, web-search-mcp 90% (#1091 in PR #1078) |
| **Jira Integration** | 80% | Notifications (50%) | Token sync (0%) | Core client ✓, feedback sync ✓, status notifications ✓ (PR #1088), submission ✓ (PR #1147), comment batching pending |
| **Notification System** | 90% | Research progress (0%) | — | Drawer ✓, SSE ✓, Jira status ✓, submission ✓, research events not wired |
| **Testing - Acceptance** | 95% | — | — | 120 feature files, 2,661 step definitions, comprehensive Cucumber/Gherkin coverage |
| **Testing - E2E** | 40% | — | 60% | Health checks ✓, message flow ✓, 5 E2E scenarios pending (#90, #92, #95, #97, #101) |
| **Testing - Evaluation** | 0% | — | 100% | Framework documented, zero eval configs deployed (#942, #1084) |
| **Observability** | 60% | MLflow (80%) | Sumo Logic (0%) | OpenTelemetry ✓, Prometheus ✓, MLflow in worktree (#482), Sumo onboarding not started (#1066) |
| **Research/AI** | 90% | Revalidation (80%) | — | Discovery ✓, agents ✓, gates ✓, revalidation in PR #1077 |
| **Frontend - Core** | 100% | — | — | Session management, research topology, gathered info, phase transitions complete |
| **Frontend - Enhancements** | 0% | — | 100% | Search/filter, kebab menus, help modal, masthead (#1156, #1155, #1154, #1153) |
| **Deployment** | 100% | — | — | Helm chart ✓, ArgoCD ✓, CI/CD ✓, local dev (Tilt) ✓ |

---

## 2. Issue Relationships

### Component Clusters

#### Notification System (7 issues, HIGH density)
**Shared infrastructure**: `NotificationDrawer.tsx`, `feedback-sync-worker.ts`, notification handlers, SSE channel, deep-linking (#752)

- **Core (done)**: #488 ✓, #493 ✓, #687 ✓ (PR #1088 merged)
- **In progress**: #754 (PR #1147 open), #755 (status done via #1088, comments pending)
- **Blocked**: #753 (infrastructure ready, event emission not started)

**Impact**: All seven share notification database, SSE infrastructure, and deep-linking. Changes to notification schema affect entire cluster.

#### Evaluation Harness (12 issues, EXTREME density)
**Blocker**: agent-eval-harness integration incomplete

- **Parent**: #942 (skill eval tools)
- **Children**: #948, #944, #951, #953, #949, #950, #945, #946, #947, #952 (9 skill-specific eval issues)
- **Related**: #1084 (agent eval, distinct from skill eval), #956 (checkpoints/tracing spike)
- **Status**: Zero eval configs deployed despite open PR #953
- **Component**: `.agents/skills/*/eval/` directories (all absent)

**Impact**: All 12 blocked on same infrastructure gap. No eval/ directories exist in main branch.

#### E2E Testing (7 issues, LOW density)
**Independent scenarios, can parallelize**

- **Tracker**: #84
- **Done**: #88 ✓, #89 ✓, #94 ✓, #96 ✓, #98 ✓, #99 ✓, #100 ✓, #102 ✓
- **Pending**: #90 (OAuth flow), #92 (Jira API), #95 (session creation), #97 (OAuth connect), #101 (mock strategy), #495 (idle detection)
- **Component**: `features/*-e2e-*.feature` files, @e2e tag scenarios

#### Jira Integration (6 issues, MEDIUM density)
**Shared JiraClient but distinct features**

- **Core (done)**: #493 ✓ (feedback sync), #687 ✓ (status notifications)
- **Partial**: #754 (submission notifications, PR #1147), #755 (feedback notifications, status done, comments pending)
- **Not started**: #168 (token sync), #92 (E2E test)
- **Component**: `JiraClient`, `FeedbackSyncWorker`, notification handlers

#### MCP/External Integrations (4 issues, LOW density)
**Independent MCP servers**

- **Done**: drive-mcp ✓, arxiv-mcp ✓
- **Near-complete**: #1091 (web-search-mcp, PR #1078 draft, 90% done)
- **Not started**: #757 (Slack MCP), #756 (Slack app credentials), #33 (Slack spike)
- **Component**: `mcp-manager.ts`, auth-proxy, token-service, server registry

#### UI Polish (5 issues, LOW density)
**Independent UI improvements, all v1.3**

- #1156 (kebab menu bug), #1155 (sidebar search), #1154 (masthead dropdown), #1153 (help modal), #923 (refinement signposting)
- **Component**: PatternFly/React components

### Potential Duplicates

1. **#687 (CLOSED) vs #755 (OPEN)**: Both describe "Jira updates as notifications"
   - **#687**: Generic "surface Jira updates" — closed via PR #1088 (status transitions)
   - **#755**: Specific acceptance criteria (comment batching, deep-linking, reviewer names)
   - **Verdict**: #755 is **not a duplicate** — it's a more detailed spec. #687 delivered status transitions; #755 comment batching remains unimplemented.

2. **#754 vs #687**: Both mention Jira notifications
   - **#754**: Submission lifecycle events (submitted, status changes)
   - **#687**: Reviewer feedback events
   - **Verdict**: Distinct scopes. PR #1147 claims #687 status transitions delivered elsewhere (PR #1088).

### Dependency Graph

```
#488 (notification drawer) ✓ ← #753, #754, #755
#493 (Jira feedback sync) ✓ ← #755
#752 (deep linking) ✓ ← #753, #754, #755
#1083 (agent API) ✓ ← #1084 (agent eval harness)
#855 (checkpoint templates) ✓ ← #881 (fairness checkpoints)
#756 (Slack app) ← #757 (Slack MCP)
#33 (Slack spike) ← #757
#942 (skill eval tools) ← #948, #944, #951, #953, #949, #950, #945, #946, #947, #952
#954 (provider SDK) ← #955 (AI gateway migration)
```

### Overlapping Acceptance Criteria

- **#753, #754, #755**: All require notification drawer, SSE events, deep-linking, session metadata
- **#948-#952 (9 issues)**: All require agent-eval-harness integration, eval.yaml configs, test cases
- **#90, #92, #95, #97**: All require E2E test infrastructure enhancements

### Scope Conflicts

**None detected** — issues are orthogonal or explicitly sequenced.

---

## 3. PR Coverage

| PR | Issue | Status | What It Delivers | What It Doesn't |
|----|-------|--------|------------------|-----------------|
| #1147 | #754 | Open | Idea submission notifications (success/failure), deep-link to synthesis | Jira status transition notifications (claims those are in PR #1088) |
| #1088 | #687 | Open | Jira status change notifications, comment notifications, deep-linking | N/A (appears complete for #687) |
| #1078 | #1091 | Draft | Web-search-mcp Helm unittest, preprod/prod enablement | Production Tavily API key, architecture docs update |
| #1077 | #875 | Open | Post-research conflict detection, discovery assumption revalidation (29 files) | Unknown — needs review |
| #1096 | — | Open | Fix Tilt Helm OCI metadata issue for MLflow | Not tied to milestone issue |
| #953 | #948 | Open | Implement skill eval config and test cases (17 files) | No eval/ directory visible in main branch yet |
| #943 | #923 | Open | Refinement gate warning guidance (4 files) | Broader refinement UX issues |
| #855 | — | Open | DoD/DoR checkpoint templates (39 files) | Fairness/bias criteria (#881) |
| #838 | — | Open | Stryker mutation testing tracking (9 files) | Not referenced by any open issue |
| #237 | — | Open | OpenShell sandboxing investigation (7 files) | Related to #957 but predates it |

---

## 4. Missing Tasks (Gaps Not Covered by Issues)

### Critical Gaps

1. **Research progress notification event emission** (#753 infrastructure exists, events not wired)
   - SSE channel ready, NotificationDrawer ready
   - Missing: orchestrator event emission on agent start/complete/fail
   - **Location**: `packages/session-pod/src/orchestrator-impl.ts`, research dispatcher
   - **Estimated effort**: 1-2 days

2. **Jira comment batch notification logic** (#755 partial)
   - Status notifications done (PR #1088)
   - Missing: comment batching, "2 new comments" aggregation
   - **Location**: `packages/gateway/src/feedback-sync-worker.ts`
   - **Estimated effort**: 2-3 days

3. **E2E mock/stub implementations** (#101 open but no detail)
   - Test strategy doc exists (ADR-0023)
   - Missing: Concrete Vertex AI mock, Jira API stub, OAuth flow doubles
   - **Location**: `features/step_definitions/support/`
   - **Estimated effort**: 1 week

4. **Eval harness CI integration** (#942 documented but not automated)
   - Framework referenced, eval.yaml schema known
   - Missing: CI workflow job, baseline storage, regression thresholds
   - **Location**: `.github/workflows/`, `.agents/skills/*/eval/`
   - **Estimated effort**: 3-5 days

5. **MLflow merge to main** (#482 in worktree only)
   - Feature file exists in `.worktrees/875-research-revalidate-discovery/features/0601-mlflow-tracing.feature`
   - Helm templates exist (`deploy/helm/ideabot/templates/mlflow/`)
   - Missing: Main branch merge, Tiltfile integration complete
   - **Estimated effort**: 1-2 days (review + merge)

6. **Sumo Logic onboarding config** (#1066 tasks listed, not started)
   - Onboarding repo MR not created
   - Missing: `config/<Dept>/IdeaBot.yml`, `observability.md` updates
   - **Estimated effort**: 4-6 hours

7. **Web-search-mcp production readiness** (#1091 90% done)
   - Server deployed, Helm tests in PR #1078
   - Missing: Production Tavily API key in Bitwarden, `docs/architecture/session-pod.md` update
   - **Estimated effort**: 2-3 hours

### Moderate Gaps

8. **Jira bot token lifecycle automation** (#168 scoped but zero implementation)
   - Manual `sync-secrets.sh` exists
   - Missing: Token-service Jira provider, expiry monitoring, auto-refresh
   - **Estimated effort**: 1-2 weeks

9. **Fairness/bias checkpoint criteria** (#881 foundation exists, criteria missing)
   - DoD/DoR templates from #855 (PR open)
   - Missing: Specific YAML criteria for bias detection, fairness verification
   - **Estimated effort**: 3-5 days (requires SME input)

10. **Agent eval harness integration** (#1084 API ready, framework not integrated)
    - #1083 closed (agent API delivered)
    - Missing: Dataset curation, rubric-based scoring, CI regression detection
    - **Estimated effort**: 2-3 weeks

---

## 5. Issues to Break Down (Too Coarse)

| Issue | Why Too Coarse | Suggested Subtasks |
|-------|---------------|-------------------|
| **#84** (E2E testing strategy) | Tracker with 6+ heterogeneous sub-issues spanning test types, infrastructure, CI | Already broken down into #90, #92, #95, #97, #101 — close #84 as meta-tracker |
| **#1084** (Agent eval harness) | Spans dataset curation, scoring, regression detection, per-agent isolation (4+ weeks) | 1) Dataset curation pipeline, 2) Rubric-based scoring framework, 3) CI regression checks, 4) Per-agent execution API wiring |
| **#942** (Skill eval tools) | Parent of 9 child issues, but lacks implementation plan | Already broken down — missing: CI workflow integration (new issue) |
| **#955** (AI gateway migration) | Architectural change spanning session pod SDK, Helm chart, local dev, model config (3-4 weeks) | 1) Provider-agnostic SDK integration (#954 dependency), 2) MaaS endpoint configuration, 3) Local dev LiteLLM proxy, 4) Streaming/tool-use validation, 5) Helm chart updates |
| **#62** (Collaborative sessions) | Covers session sharing, real-time updates, access control, attribution (4+ features, 4+ weeks) | 1) Session invite link generation, 2) Multi-user SSE fanout, 3) Access control (owner vs collaborator), 4) Change attribution tracking, 5) Conflict resolution |
| **#1036** (Reporting dashboard) | Aggregate metrics across 5+ dimensions with privacy constraints (3+ weeks) | 1) Metric collection (phase funnel, drop-off), 2) Privacy-preserving aggregation, 3) Dashboard UI (PatternFly charts), 4) Time-series storage |

---

## 6. Critical Path

### What Blocks What

**Short-term blockers (this sprint)**:
- #753, #754, #755 dependencies satisfied (infrastructure done) — **can start immediately**
- #1091 blocked on: production Tavily API key (procurement)
- #948-#952 (skill evals) blocked on: #942 CI integration (missing subtask)
- #1084 blocked on: dataset curation decision (missing subtask)

**Medium-term blockers (next 2 sprints)**:
- #757 (Slack MCP) blocked on: #756 (Slack app credentials)
- #955 (AI gateway) blocked on: #954 (provider SDK migration) completion
- #881 (fairness checkpoints) blocked on: #855 (PR #855 merge)

**Long-term blockers (v1.4+)**:
- #958 (agentic memory) blocked on: spike findings, vector DB selection
- #957 (managed sandbox) blocked on: Openshell/Agent Sandbox GA
- #62 (collaborative sessions) blocked on: multi-user auth strategy

### What Can Start Now

**Ready to implement** (dependencies satisfied):
1. #753 — Research progress notifications (infra done, event emission remains)
2. #755 — Jira comment batching (status notifications done, comment aggregation remains)
3. #1066 — Sumo Logic onboarding (documentation task, no code dependencies)
4. #1156, #1155, #1154, #1153 — UI polish (independent frontend changes)
5. #90, #92, #95, #97 — E2E test scenarios (framework ready)
6. #589 — Research agent sidebar enhancements (UI-only)

**Blocked but unblock-able** (missing decisions/procurement, not code):
1. #1091 — Web-search-mcp (needs Tavily API key from Bitwarden)
2. #1084 — Agent eval dataset curation (needs dataset scope decision)
3. #168 — Jira token sync (needs token lifecycle design review)

### Recommended Sequencing

**Phase 1 (v1.2 completion)**:
1. Complete notification trio (#753, #755 comment batching, merge #1147)
2. Merge #1078 (web-search-mcp), procure Tavily key, update docs
3. Merge #1077 (research revalidation)
4. Add CI job for skill evals (#942 subtask)
5. Complete Sumo Logic onboarding (#1066)

**Phase 2 (v1.3 foundation)**:
1. E2E test expansion (#90, #92, #95, #97)
2. UI polish sprint (#1156, #1155, #1154, #1153, #923)
3. Agent eval dataset curation (#1084 subtask 1)
4. Slack app credential request (#756)

**Phase 3 (v1.3 delivery)**:
1. AI gateway migration planning (#955, dependency on #954)
2. Slack MCP integration (#757, after #756)
3. Agent eval scoring framework (#1084 subtask 2)
4. Fairness checkpoint criteria (#881, after #855 merge)

---

## 7. Recommendations

### Issues to Merge/Close

1. **Close #84 as meta-tracker** — all substantive work captured in child issues (#90, #92, #95, #97, #101)
2. **Verify #687 vs #755 overlap** — if #1088 already delivers #755 acceptance criteria, close #755 as duplicate; otherwise clarify remaining scope in #755 description
3. **Close #237 or link to #957** — PR #237 is OpenShell investigation; if it's obsolete, close; if it informs #957, reference it

### Issues to Split

1. **#1084** → Create 4 subtasks:
   - Dataset curation pipeline
   - Rubric-based scoring implementation
   - CI regression check integration
   - Per-agent execution wiring

2. **#955** → Create 5 subtasks:
   - Provider-agnostic SDK integration
   - MaaS endpoint Helm configuration
   - Local dev gateway substitute (LiteLLM)
   - Streaming/tool-use validation suite
   - Migration documentation

3. **#62** → Create 5 subtasks:
   - Session invite link generation
   - Multi-user SSE fanout
   - Access control implementation
   - Change attribution
   - Conflict resolution

4. **#1036** → Create 4 subtasks:
   - Metric collection instrumentation
   - Privacy-preserving aggregation
   - Dashboard UI components
   - Time-series storage backend

### Issues to Resequence

1. **Move #1066 (Sumo Logic) earlier** — documentation task, no dependencies, unblocks telemetry access
2. **Deprioritize #955 (AI gateway) until #954 closes** — architectural dependency not yet satisfied
3. **Batch UI polish** (#1156, #1155, #1154, #1153) into single sprint for design consistency

### Missing Issues to Create

1. **"Integrate agent-eval-harness into CI workflow"** — bridges #942 and its 9 children
2. **"Procure production Tavily API key"** — unblocks #1091 final acceptance criterion
3. **"Merge MLflow tracing from worktree 875"** — unblocks #482 closure
4. **"Complete Jira comment batching logic"** — unblocks #755 closure
5. **"Emit research progress events from orchestrator"** — unblocks #753 closure
6. **"Update session-pod.md for web-search provider parity"** — unblocks #1091 closure
7. **"Design Jira bot token lifecycle in token-service"** — unblocks #168 implementation

---

## Appendix: Detailed Issue Inventory

### No Milestone (5 issues)

| # | Title | Status | Notes |
|---|-------|--------|-------|
| 1151 | feat: Add evaluation pipeline for the Web Search Agent | Open | Not scoped to milestone |
| 1050 | Local dev on Fedora: CRI-O can't find images built | Open | Environment-specific issue |
| 126 | Dependency Dashboard | Open | Renovate automation |
| 64 | VP/Director filtered dashboard | Open | Future feature |
| 44 | Investigate Forge app for custom Jira views | Open | Spike/investigation |

### IdeaBot v1.2 (20 issues)

| # | Title | Status | PR | Readiness |
|---|-------|--------|-----|-----------|
| 1148 | [Feedback] Multiple choice workflow error spam | Open | — | Not started |
| 1091 | Complete integration of provider-agnostic web search with Tavily MCP | Open | #1078 | 90% (blocked on API key) |
| 1084 | IdeaBot agent and LLM evaluation harness | Open | — | Needs breakdown |
| 1066 | Migrate IdeaBot telemetry access from Splunk to Sumo Logic | Open | — | Ready to start |
| 956 | Spike: Checkpoints and evals tracing for LLM calls | Open | — | Not started |
| 948 | Eval harness support for `/implement` skill | Open | #953 | Blocked on CI integration |
| 944 | Eval harness support for `/address-review` skill | Open | — | Blocked on CI integration |
| 942 | [feat]: Implement required skill evaluation tools | Open | — | Missing CI subtask |
| 923 | [Feedback] Refinement page signposting | Open | #943 | In PR |
| 875 | feat: research phase should re-validate Discovery assumptions | Open | #1077 | 80% (in PR) |
| 755 | Jira feedback item notifications | Open | — | 50% (status done, comments pending) |
| 754 | Idea submission confirmation notification | Open | #1147 | 80% (in PR) |
| 753 | Research agent progress notifications | Open | — | Ready to start |
| 589 | Enhance research agent detail sidebar | Open | — | Ready to start |
| 482 | Enable MLflow tracing for LLM calls | Open | — | 80% (in worktree) |
| 168 | Sync Jira bot-account tokens/refresh into IdeaBot token service | Open | — | Needs design |
| 101 | E2E test: Mock/stub strategy for external services | Open | — | Needs detail |
| 92 | E2E test: Gateway → Jira API | Open | — | Ready to start |
| 90 | E2E test: Gateway → Token Service OAuth flow | Open | — | Ready to start |
| 84 | E2E and integration testing strategy | Open | — | Close as meta-tracker |

### IdeaBot v1.3 (10 issues)

| # | Title | Status | Notes |
|---|-------|--------|-------|
| 1156 | Fix multiple kebab menus opening simultaneously | Open | Ready to start |
| 1155 | Add search/filter to session sidebar | Open | Ready to start |
| 1154 | Restructure masthead user dropdown | Open | Ready to start |
| 1153 | Redesign "Help Us Improve" modal | Open | Ready to start |
| 1036 | Reporting dashboard for aggregate system metrics | Open | Needs breakdown |
| 955 | Switch to an externally provided AI gateway | Open | Blocked on #954 |
| 951 | Eval harness support for `/find-docs` skill | Open | Blocked on CI integration |
| 881 | feat: Fairness, bias, and AI constraint checkpoints | Open | Blocked on #855 merge |
| 585 | Add local_resource to Tiltfile for automatic Vertex AI token seeding | Open | Not started |
| 455 | Expose IdeaBot as an MCP server | Open | Not started |

### IdeaBot v1.4 (6 issues)

| # | Title | Status | Notes |
|---|-------|--------|-------|
| 958 | Spike: Agentic memory and vector knowledge base | Open | Not started |
| 957 | Migrate to a managed sandbox solution | Open | Waiting on upstream |
| 757 | Integrate Slack MCP server and implement research agent | Open | Blocked on #756 |
| 756 | Request Slack app with user OAuth permissions | Open | Not started |
| 62 | Collaborative idea sessions | Open | Needs breakdown |
| 33 | Spike: Slack integration | Open | Not started |

---

## Codebase Context (From Exploration Agents)

### Implemented Components

**Fully operational**:
- ✅ Gateway service (session lifecycle, warm pool, Kubernetes orchestration, SSE proxy, notification system)
- ✅ Session pod (orchestrator with MCP management, research agents, discovery/refinement/synthesis)
- ✅ Token service (OAuth flows, credential encryption, token refresh)
- ✅ Auth proxy (Go-based sidecar, path-based routing, token injection)
- ✅ Frontend (React 19 + PatternFly 6, 34 components, session management)
- ✅ Database schema (11 migrations, sessions/credentials/feedback/notifications)
- ✅ Helm deployment (59 templates, production-ready)
- ✅ CI/CD (comprehensive workflow: lint, test, image builds, EARS audit)
- ✅ Local dev (Tilt-based MINC with hot reload)
- ✅ MCP servers (drive-mcp, web-search-mcp, arxiv-mcp)

**Partial implementation**:
- 🔨 Web-search-mcp (90% — missing production API key, docs update)
- 🔨 MLflow tracing (80% — in worktree, needs main branch merge)
- 🔨 Notification system (90% — drawer/SSE complete, research events not emitted)
- 🔨 Jira notifications (80% — status transitions complete, comment batching pending)

**Not implemented**:
- ❌ Slack MCP integration
- ❌ Agent/skill evaluation harness (framework documented, zero configs deployed)
- ❌ Sumo Logic telemetry access
- ❌ Jira bot token lifecycle automation
- ❌ E2E mock/stub implementations

### Key Architectural Patterns

- **Monorepo** — npm workspaces, shared `@hermes/core` package
- **Pod-per-session** — stateless session pods with PostgreSQL persistence
- **Warm pool** — pre-initialized pods for fast session startup
- **Leader election** — Kubernetes Lease-based for pool management
- **Sidecar pattern** — auth proxy for credential injection
- **Server registry** — single-source-of-truth ConfigMap for MCP server config
- **BDD testing** — EARS requirements in Gherkin feature files

### File Structure Summary

- **Packages**: 8 (core, gateway, session-pod, token-service, frontend, auth-proxy, drive-mcp, web-search-mcp)
- **Feature files**: 120
- **Step definitions**: 2,661
- **Helm templates**: 59
- **Containerfiles**: 8
- **ADRs**: 24
- **Open PRs**: 9
- **Worktrees**: Multiple (875-research-revalidate-discovery contains MLflow work)
