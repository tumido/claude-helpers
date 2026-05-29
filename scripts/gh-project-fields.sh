#!/bin/bash
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: gh-project-fields <owner> <project-number>" >&2
  exit 1
fi

OWNER=$1
PROJECT=$2

gh api graphql -f query="
{
  organization(login: \"$OWNER\") {
    projectV2(number: $PROJECT) {
      id
      field(name: \"Status\") {
        ... on ProjectV2SingleSelectField {
          id
          options { id name }
        }
      }
    }
  }
}" | jq '{
  project_id: .data.organization.projectV2.id,
  status_field_id: .data.organization.projectV2.field.id,
  statuses: (.data.organization.projectV2.field.options | map({(.name): .id}) | add)
}'
