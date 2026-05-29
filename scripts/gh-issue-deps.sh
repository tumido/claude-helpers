#!/bin/bash
set -euo pipefail

if [ $# -lt 3 ]; then
  echo "Usage: gh-issue-deps <owner> <repo> <issue-number> [issue-number...]" >&2
  exit 1
fi

OWNER=$1
REPO=$2
shift 2

for ISSUE in "$@"; do
  gh api graphql -f query="
  {
    repository(owner: \"$OWNER\", name: \"$REPO\") {
      issue(number: $ISSUE) {
        id
        number
        title
        state
        blockedBy(first: 10) {
          nodes { number title state }
          totalCount
        }
        closedByPullRequestsReferences(first: 5) {
          nodes { number title state }
        }
      }
    }
  }" | jq '.data.repository.issue | {
    node_id: .id,
    number,
    title,
    state,
    blocked_by: [(.blockedBy.nodes // [])[] | {number, title, state}],
    blocked_by_count: (.blockedBy.totalCount // 0),
    closed_by_prs: [(.closedByPullRequestsReferences.nodes // [])[] | {number, title, state}]
  }'
done
