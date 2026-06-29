#!/bin/bash
set -euo pipefail

RUN_ID=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --run-id) RUN_ID="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: update-baselines.sh [--run-id <ID>]"
      echo ""
      echo "Download visual baseline artifacts from a failed CI run"
      echo "and replace local baselines."
      echo ""
      echo "Options:"
      echo "  --run-id <ID>  Use a specific workflow run instead of auto-detecting"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

ARTIFACT_KEYWORDS='screenshot|snapshot|visual|baseline|test-results|playwright-report|diff'

cleanup() {
  if [ -n "${TMPDIR_BASELINES:-}" ] && [ -d "$TMPDIR_BASELINES" ]; then
    rm -rf "$TMPDIR_BASELINES"
  fi
}
trap cleanup EXIT

# ── Step 1: Verify PR context ───────────────────────────────────────────────

echo "==> Checking PR context..."
BRANCH=$(git branch --show-current)
PR_JSON=$(gh pr view --json number,headRefName 2>/dev/null || true)

if [ -z "$PR_JSON" ] || [ "$PR_JSON" = "" ]; then
  echo "ERROR: No PR found for branch '$BRANCH'" >&2
  exit 1
fi

PR_NUMBER=$(echo "$PR_JSON" | jq -r '.number')
HEAD_REF=$(echo "$PR_JSON" | jq -r '.headRefName')
echo "    PR #$PR_NUMBER on branch $HEAD_REF"

# ── Step 2: Find the failed run with artifacts ──────────────────────────────

REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')

if [ -n "$RUN_ID" ]; then
  echo "==> Using provided run ID: $RUN_ID"
else
  echo "==> Finding failed runs with visual artifacts..."
  RUNS=$(gh run list --branch "$HEAD_REF" --status failure --limit 10 \
    --json databaseId,name,conclusion,createdAt)

  RUN_COUNT=$(echo "$RUNS" | jq 'length')
  if [ "$RUN_COUNT" -eq 0 ]; then
    echo "ERROR: No failed runs found for branch '$HEAD_REF'" >&2
    exit 1
  fi

  for i in $(seq 0 $((RUN_COUNT - 1))); do
    CANDIDATE=$(echo "$RUNS" | jq -r ".[$i].databaseId")
    RUN_NAME=$(echo "$RUNS" | jq -r ".[$i].name")

    ARTIFACTS=$(gh api "repos/$REPO/actions/runs/$CANDIDATE/artifacts" \
      --jq '[.artifacts[] | select(.expired == false) | {id, name, size_in_bytes}]' 2>/dev/null || echo '[]')

    MATCHING=$(echo "$ARTIFACTS" | jq --arg kw "$ARTIFACT_KEYWORDS" \
      '[.[] | select(.name | test($kw; "i"))]')

    MATCH_COUNT=$(echo "$MATCHING" | jq 'length')
    if [ "$MATCH_COUNT" -gt 0 ]; then
      RUN_ID="$CANDIDATE"
      echo "    Found run $RUN_ID ($RUN_NAME) with $MATCH_COUNT matching artifact(s):"
      echo "$MATCHING" | jq -r '    .[] | "      \(.name) (\(.size_in_bytes) bytes)"'
      break
    fi
  done

  if [ -z "$RUN_ID" ]; then
    echo "ERROR: No failed runs have visual testing artifacts" >&2
    echo "    Looked for artifacts matching: $ARTIFACT_KEYWORDS" >&2
    exit 1
  fi
fi

# ── Step 3: Download artifacts ──────────────────────────────────────────────

TMPDIR_BASELINES=$(mktemp -d)
echo "==> Downloading artifacts from run $RUN_ID..."

ARTIFACTS=$(gh api "repos/$REPO/actions/runs/$RUN_ID/artifacts" \
  --jq '[.artifacts[] | select(.expired == false) | {id, name, size_in_bytes}]')

MATCHING=$(echo "$ARTIFACTS" | jq --arg kw "$ARTIFACT_KEYWORDS" \
  '[.[] | select(.name | test($kw; "i"))]')

MATCH_COUNT=$(echo "$MATCHING" | jq 'length')
if [ "$MATCH_COUNT" -eq 0 ]; then
  echo "ERROR: Run $RUN_ID has no matching visual artifacts" >&2
  echo "    Available artifacts:" >&2
  echo "$ARTIFACTS" | jq -r '    .[] | "      \(.name)"' >&2
  exit 1
fi

for i in $(seq 0 $((MATCH_COUNT - 1))); do
  NAME=$(echo "$MATCHING" | jq -r ".[$i].name")
  echo "    Downloading: $NAME"
  gh run download "$RUN_ID" -n "$NAME" -D "$TMPDIR_BASELINES"
done

DOWNLOADED_FILES=$(find "$TMPDIR_BASELINES" -type f -name '*.png' | sort)
DOWNLOAD_COUNT=$(echo "$DOWNLOADED_FILES" | grep -c . || true)
echo "    Downloaded $DOWNLOAD_COUNT file(s)"

if [ "$DOWNLOAD_COUNT" -eq 0 ]; then
  echo "ERROR: No .png files found in downloaded artifacts" >&2
  echo "    Contents:" >&2
  find "$TMPDIR_BASELINES" -type f | head -20 >&2
  exit 1
fi

# ── Step 4: Discover baseline location ──────────────────────────────────────

echo "==> Discovering baseline location..."
BASELINE_DIR=""

for cfg in playwright.config.ts playwright.config.js cypress.config.ts cypress.config.js; do
  if [ -f "$cfg" ]; then
    SNAPSHOT_DIR=$(grep -oP '(?:snapshotDir|snapshotPathTemplate|screenshotsFolder)["\s:]*["\x27]([^"\x27]+)' "$cfg" 2>/dev/null | head -1 | grep -oP '["\x27][^"\x27]+["\x27]$' | tr -d "\"'" || true)
    if [ -n "$SNAPSHOT_DIR" ]; then
      BASELINE_DIR="$SNAPSHOT_DIR"
      echo "    Found snapshot dir in $cfg: $BASELINE_DIR"
      break
    fi
  fi
done

if [ -z "$BASELINE_DIR" ]; then
  EXISTING_DIRS=$(find . -type d \( -name '*snapshots*' -o -name '*screenshots*' -o -name '*baselines*' \) \
    -not -path '*/node_modules/*' -not -path '*/.claude/*' -not -path '*/.git/*' 2>/dev/null | head -10)
  if [ -n "$EXISTING_DIRS" ]; then
    BASELINE_DIR=$(echo "$EXISTING_DIRS" | head -1)
    echo "    Found baseline directory: $BASELINE_DIR"
  fi
fi

# ── Step 5: Copy updated baselines ──────────────────────────────────────────

echo "==> Copying updated baselines..."
UPDATED=0
SKIPPED=0

while IFS= read -r src; do
  [ -z "$src" ] && continue
  fname=$(basename "$src")

  if echo "$fname" | grep -qiE '(-diff|-expected)\.(png|jpg|jpeg)$'; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  target_name="$fname"
  if echo "$fname" | grep -qiE -- '-actual\.(png|jpg|jpeg)$'; then
    target_name=$(echo "$fname" | sed -E 's/-actual\.(png|jpg|jpeg)$/.\1/i')
  fi

  dest=""
  if [ -n "$BASELINE_DIR" ]; then
    existing=$(find "$BASELINE_DIR" -name "$target_name" -type f 2>/dev/null | head -1)
    if [ -n "$existing" ]; then
      dest="$existing"
    fi
  fi

  if [ -z "$dest" ]; then
    existing=$(find . -name "$target_name" -type f \
      -not -path '*/node_modules/*' -not -path '*/.claude/*' -not -path '*/.git/*' 2>/dev/null | head -1)
    if [ -n "$existing" ]; then
      dest="$existing"
    fi
  fi

  if [ -z "$dest" ] && [ -n "$BASELINE_DIR" ]; then
    dest="$BASELINE_DIR/$target_name"
  fi

  if [ -z "$dest" ]; then
    echo "    SKIP: No destination found for $fname" >&2
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "    Updated: $dest"
  UPDATED=$((UPDATED + 1))
done <<< "$DOWNLOADED_FILES"

echo ""
echo "    $UPDATED baseline(s) updated, $SKIPPED skipped"

if [ "$UPDATED" -eq 0 ]; then
  echo "ERROR: No baselines were updated" >&2
  exit 1
fi

echo ""
echo "==> Done. Review the changes and commit when ready."
