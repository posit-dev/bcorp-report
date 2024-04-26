#!/usr/bin/ bash

OWNER='quarto-dev'
REPO='quarto-cli'

OUTPUT_FILE="releases.csv"

QUERY='
query ($owner: String!, $repo: String!, $cursor: String) {
  repository(name: $repo, owner: $owner) {
    releases(first: 100, after: $cursor) {
      nodes {
        createdAt
        releaseAssets(first: 100) {
          nodes {
            name
            downloadCount
          }
        }
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
}
'

RESULTS='[]'

PAGE=0
RESPONSE=$(gh api graphql -f query="${QUERY}" -f owner="${OWNER}" -f repo="${REPO}")
RESULTS=$(echo "${RESULTS}" | jq --argjson response "${RESPONSE}" '. + $response.data.repository.releases.nodes')

CURSOR=$(gh api graphql -f query="${QUERY}" -f owner="${OWNER}" -f repo="${REPO}" | jq -r '.data.repository.releases.pageInfo | select(.hasNextPage == true) | .endCursor')
while true; do
  PAGE=$((PAGE + 1))
  echo "Fetching page $PAGE"
  RESPONSE=$(gh api graphql -f query="${QUERY}" -f owner="${OWNER}" -f repo="${REPO}" -f cursor="${CURSOR}")
  RESULTS=$(echo "${RESULTS}" | jq --argjson response "${RESPONSE}" '. + $response.data.repository.releases.nodes')
  CURSOR=$(echo "${RESPONSE}" | jq -r '.data.repository.releases.pageInfo | select(.hasNextPage == true) | .endCursor')
  echo "Cursor: ${CURSOR}"
  if [ "${CURSOR}" = "" ]; then
    break
  fi
done

echo "created,name,download_count" > "${OUTPUT_FILE}"
echo "${RESULTS}" | jq -r '.[] | .createdAt as $date | .releaseAssets.nodes[] | [$date, .name, .downloadCount] | @csv' >> "${OUTPUT_FILE}"