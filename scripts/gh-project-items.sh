#!/bin/bash
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: gh-project-items <owner> <project-number>" >&2
  exit 1
fi

OWNER=$1
PROJECT=$2

ALL_ITEMS='[]'
CURSOR=""

while true; do
  AFTER=""
  if [ -n "$CURSOR" ]; then
    AFTER=", after: \"$CURSOR\""
  fi

  RESULT=$(gh api graphql -f query="
  {
    organization(login: \"$OWNER\") {
      projectV2(number: $PROJECT) {
        items(first: 100$AFTER) {
          nodes {
            id
            fieldValueByName(name: \"Status\") {
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                optionId
              }
            }
            content {
              ... on Issue {
                number
                title
                state
                body
                labels(first: 10) { nodes { name } }
                milestone { title }
                parent { number title }
                assignees(first: 5) { nodes { login } }
                trackedInIssues(first: 5) { nodes { number title } }
                blockedBy(first: 10) {
                  nodes { number title state }
                  totalCount
                }
              }
            }
          }
          pageInfo { hasNextPage endCursor }
        }
      }
    }
  }")

  PAGE=$(echo "$RESULT" | jq '.data.organization.projectV2.items.nodes')
  ALL_ITEMS=$(jq -s '.[0] + .[1]' <(echo "$ALL_ITEMS") <(echo "$PAGE"))

  HAS_NEXT=$(echo "$RESULT" | jq -r '.data.organization.projectV2.items.pageInfo.hasNextPage')
  if [ "$HAS_NEXT" != "true" ]; then
    break
  fi
  CURSOR=$(echo "$RESULT" | jq -r '.data.organization.projectV2.items.pageInfo.endCursor')
done

echo "$ALL_ITEMS" | jq '[.[] | select(.content.number != null) | {
  item_id: .id,
  status: (.fieldValueByName // {}).name,
  status_option_id: (.fieldValueByName // {}).optionId,
  number: .content.number,
  title: .content.title,
  state: .content.state,
  body: .content.body,
  labels: [(.content.labels.nodes // [])[] | .name],
  milestone: (.content.milestone // {}).title,
  parent: (.content.parent // null),
  assignees: [(.content.assignees.nodes // [])[] | .login],
  tracked_in: [(.content.trackedInIssues.nodes // [])[] | {number, title}],
  blocked_by: [(.content.blockedBy.nodes // [])[] | {number, title, state}],
  blocked_by_count: ((.content.blockedBy // {}).totalCount // 0)
}]'
