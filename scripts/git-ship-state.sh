#!/bin/bash
set -euo pipefail

# Gather all git state needed by the ship command in a single call.
# Output is sectioned with headers for easy parsing.

echo "=== STATUS ==="
git status --short

echo "=== BRANCH ==="
git branch --show-current

echo "=== DEFAULT_BRANCH ==="
git rev-parse --abbrev-ref origin/HEAD 2>/dev/null || echo origin/main

echo "=== UPSTREAM ==="
upstream_ref=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
if [ -n "$upstream_ref" ]; then
  echo "ref: $upstream_ref"
  echo "--- unpushed ---"
  git log "$upstream_ref..HEAD" --oneline
else
  echo "none"
fi

default_branch=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null || echo origin/main)

echo "=== COMMITS ==="
git log --oneline "$default_branch..HEAD"

echo "=== DIFFSTAT ==="
git diff "$default_branch...HEAD" --stat
