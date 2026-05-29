#!/bin/bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: gh-search-issues <query>" >&2
  exit 1
fi

QUERY=$1

gh api graphql -f query="
{
  search(query: \"$QUERY\", type: ISSUE, first: 30) {
    nodes {
      ... on Issue {
        number
        title
        state
        repository { nameWithOwner }
        labels(first: 5) { nodes { name } }
        milestone { title }
        assignees(first: 3) { nodes { login } }
      }
    }
  }
}" | jq '[.data.search.nodes[] | {
  number,
  title,
  state,
  repo: .repository.nameWithOwner,
  labels: [(.labels.nodes // [])[] | .name],
  milestone: (.milestone // {}).title,
  assignees: [(.assignees.nodes // [])[] | .login]
}]'
