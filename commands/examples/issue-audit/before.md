# Issue Tracker Audit Report

## Current State by Area

| Area | Implementation Status | Notes |
|------|----------------------|-------|
| **Frontend (Web UI)** | ✅ Production-ready | 34 components, all features working, no scaffolding |
| **Gateway Backend** | ✅ Production-ready | Full session mgmt, Jira integration, OAuth, notifications |
| **Session Pod AI** | ✅ Production-ready | 7 research agents, gate evaluation, synthesis working |
| **Infrastructure** | ✅ Production-ready | Comprehensive Helm charts, 8 NetworkPolicies, CI/CD |
| **E2E Tests** | ⚠️ Partial | 5 features exist, missing OAuth/Jira/session creation |
| **Eval Harness** | ❌ Not started | No agent evaluation framework exists |
| **MLflow Tracing** | ❌ Not started | OpenTelemetry exists, but not MLflow |
| **MCP Web Search** | ⚠️ Partial | Server exists, needs prod enablement (#1078 in draft) |

## Open PR Coverage

| PR | Issue | Status | Coverage |
|----|-------|--------|----------|
| #1147 | #754 | Draft | ✅ Idea submission notifications (success/failure) |
| #1096 | N/A | Draft | ✅ Helm OCI metadata fix for MLflow |
| #1078 | #1091 | Draft | ✅ Web-search-mcp preprod/prod enablement |
| #1077 | #875 | Draft | ✅ Post-research revalidation agent |
| #953 | #942 | Draft | ⚠️ Implement skill eval only (not broader eval framework) |
| #943 | #923 | Draft | ✅ Refinement gate resolution guidance |
| #855 | N/A | Draft | ✅ DoD/DoR checkpoint templates (new infrastructure) |
| #838 | N/A | Draft | ✅ Mutation testing with Stryker |
| #237 | #957 | Draft | ✅ OpenShell sandboxing for agents |

**PR Coverage Gap**: None of the open PRs address:
- General eval harness (#1084, #956)
- MLflow tracing (#482)
- E2E tests (#90, #92, #95, #97, #101)
- v1.3 UI improvements (#1155, #1156, #1153, #1154)
- AI gateway migration (#955)

## Missing Tasks (Untracked Implementation Work)

### IdeaBot v1.2 Milestone

**1. Web Search MCP Integration (#1091)** - Partially complete
- ✅ Server implemented (#1023)
- ✅ optionalTools support (#1087)
- 🔲 **Missing**: Obtain production Tavily API key
- 🔲 **Missing**: Update architecture docs

**2. Eval Harness (#1084)** - Not started
- 🔲 **Missing**: Eval dataset curation infrastructure
- 🔲 **Missing**: Automated scoring framework
- 🔲 **Missing**: Regression detection CI integration
- 🔲 **Missing**: Per-agent isolation API (depends on #1083 which is closed)
- **Blockers**: Depends on #1083 (merged), but no work has started on evaluation infrastructure

**3. Web Search Agent Eval Pipeline (#1151)** - Not started
- 🔲 **Missing**: Create `eval/` directory structure
- 🔲 **Missing**: DeepSearchQA/BrowseComp-Plus dataset integration
- 🔲 **Missing**: Evaluation harness script
- 🔲 **Missing**: Scoring metrics implementation
- 🔲 **Missing**: Search backend configurability (claude/tavily/both modes)
- **Note**: This is a standalone track, doesn't depend on #1084

**4. MLflow Tracing (#482)** - Not started
- 🔲 **Missing**: Investigate Vertex SDK compatibility with `@mlflow/anthropic`
- 🔲 **Missing**: MLflow Tracking Server deployment (Helm template exists for local, not prod)
- 🔲 **Missing**: Instrument `AIClient.sendMessage()` calls
- 🔲 **Missing**: Verify streaming trace capture
- **Current state**: MLflow server runs in local dev only (Tiltfile), no SDK integration

**5. Checkpoints/Evals Spike (#956)** - Not started
- 🔲 **Missing**: Spike summary document
- 🔲 **Missing**: POC checkpoint capture
- 🔲 **Missing**: POC eval suite
- **Note**: PR #855 (DoD/DoR templates) may partially address this, but the spike deliverables remain incomplete

**6. Skill Evaluation Tools (#942)** - Partial
- ✅ Implement skill eval (#953 in PR)
- 🔲 **Missing**: address-review eval (#944)
- 🔲 **Missing**: find-docs eval (#951)
- 🔲 **Missing**: ears-gherkin-dev eval (#952)
- 🔲 **Missing**: update-baselines, next, ship, local-deploy, done evals (#945-950)

**7. E2E Testing (#84 tracker)** - Partial
- ✅ #88, #89, #495 (closed - working)
- 🔲 **Missing**: #90 - Gateway → Token Service OAuth flow E2E
- 🔲 **Missing**: #92 - Gateway → Jira API E2E
- 🔲 **Missing**: #95 - New session creation E2E
- 🔲 **Missing**: #97 - OAuth connect flow E2E
- 🔲 **Missing**: #101 - Mock/stub strategy for external services
- **Current**: 5 E2E features exist, excluded from `npm test` by default

**8. Jira Notifications (#755, #754, #753)** - Partially complete
- ✅ #754 - Submission notifications (PR #1147)
- 🔲 **Missing**: #755 - Feedback item notifications (depends on #687 which is merged)
- 🔲 **Missing**: #753 - Research progress notifications
- **Note**: #687 (Jira status updates as notifications) is closed, but #755 (feedback-specific) is still open

**9. Reporting Dashboard (#1036)** - Not started (v1.3 milestone but may belong in v1.2)
- 🔲 **Missing**: Aggregate metrics collection
- 🔲 **Missing**: Dashboard UI

### IdeaBot v1.3 Milestone

**1. UI Improvements (#1156, #1155, #1154, #1153)** - Not started
- 🔲 **Missing**: Fix multiple kebab menus (#1156) - **bug confirmed in audit**
- 🔲 **Missing**: Add search/filter to session sidebar (#1155) - **confirmed missing**
- 🔲 **Missing**: Restructure user dropdown (#1154)
- 🔲 **Missing**: Redesign "Help Us Improve" modal (#1153)

**2. AI Gateway Migration (#955)** - Not started
- 🔲 **Missing**: Configure session pods for MaaS/gateway endpoint
- 🔲 **Missing**: Map model references to gateway subscriptions
- 🔲 **Missing**: Validate streaming/thinking/tools through gateway
- 🔲 **Missing**: Local dev gateway substitute
- **Dependency**: Blocked on provider-agnostic SDK (#954 status unknown)

### IdeaBot v1.4 Milestone

All issues appear to be future work with no current implementation.

## Integration Gaps

### 1. **Checkpoint Template Infrastructure** (PR #855)
- **Status**: Fully implemented in PR, not merged
- **Gap**: PR introduces new DoD/DoR checkpoint system, but no issue covers:
  - Checkpoint evaluator AI agent (analogous to GateEvaluator)
  - UI for displaying checkpoint results
  - Phase transition enforcement based on checkpoint status
  - Integration with existing advisory gates
- **Affected Issue**: None - this is new infrastructure, no issue requested it

### 2. **Notification System** (Working but incomplete coverage)
- **Status**: Infrastructure complete, partial integration
- **Gaps**:
  - Research progress notifications (#753) - not implemented
  - Feedback item notifications (#755) - depends on #687 (closed) but still missing

### 3. **Token Service / MCP Integration**
- **Status**: Token service working, MCP servers exist
- **Gap**: No issue tracks token sync from Jira bot account (#168 mentions it)

### 4. **Local Development Tooling**
- **Status**: Tilt working, MLflow in local only
- **Gap**: #585 (automatic Vertex AI token seeding) - not implemented

## Issues That Need Breaking Down

| Issue | Why Too Coarse | Suggested Split |
|-------|----------------|-----------------|
| #1084 | Covers dataset curation, scoring, CI integration, and per-agent isolation | (1) Eval dataset infrastructure, (2) Scoring framework, (3) CI integration, (4) Agent isolation API |
| #1151 | Covers directory structure, 2 benchmarks, 3 search modes, harness, scoring, and reproducibility | (1) Eval directory structure + harness, (2) DeepSearchQA integration, (3) BrowseComp-Plus integration, (4) Reproducibility/caching |
| #942 | Covers 11 skill evals | Already split into #944-953 (8 separate issues) |
| #84 | Tracker issue spanning 15 sub-issues | Already appropriately decomposed |
| #955 | Covers gateway config, model mapping, validation, local dev, and docs | (1) Gateway routing setup, (2) Model subscription mapping, (3) Streaming/tools validation, (4) Local dev substitute |

## Critical Path

### Ready to start now:
1. **UI improvements (#1155, #1156)** - no blockers, bugs confirmed in audit
2. **E2E test gaps (#90, #92, #95, #97)** - infrastructure exists
3. **Skill evals (#944-951)** - framework exists from #953
4. **Web search eval (#1151)** - AgentRunner API merged (#1083)
5. **MLflow spike/integration (#482, #956)** - Tracking server exists in local, needs SDK work

### Blocked:
1. **AI Gateway (#955)** - blocked on provider-agnostic SDK migration (#954 status unknown)
2. **Checkpoint evaluator** - blocked on PR #855 merge decision
3. **Tavily prod deployment (#1091)** - blocked on obtaining Tavily API key (external dependency)

### Sequencing dependencies:
- **Eval harness (#1084)** should complete before **Web search eval (#1151)** to avoid building two separate evaluation frameworks
- **MLflow spike (#956)** should inform **MLflow tracing (#482)** implementation
- **Checkpoint templates (#855)** should merge before building checkpoint evaluator

## Recommendations

1. **Merge PR #855** (DoD/DoR templates) and create follow-up issue for checkpoint evaluator
2. **Split #1084** into 3-4 focused issues (infrastructure, scoring, CI, isolation)
3. **Prioritize E2E test completion** (#90, #92, #95, #97) - low effort, high risk reduction
4. **Complete MLflow spike #956** before starting #482 to avoid rework
5. **Clarify #954 status** (provider-agnostic SDK) to unblock #955 or descope it from v1.3
