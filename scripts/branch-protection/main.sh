#!/bin/bash

# Usage: ./main.sh

# Define arrays
REPOS=(
  github-devops-javascript
  github-devops-python
  github-devops-workflows
)

BRANCHES=("main" "dev" "multitenancy")
ORG="tazama-lf"

# Ensure gh is authenticated
if ! gh auth status > /dev/null 2>&1; then
  echo "Error: GitHub CLI not authenticated. Please run 'gh auth login'."
  exit 1
fi

for repo in "${REPOS[@]}"; do
  for branch in "${BRANCHES[@]}"; do
    echo "🔐 Processing $ORG/$repo/$branch"
    # Attempt to set branch protection with no pager and timeout
    gh api --method PUT --paginate=false \
      -H "Accept: application/vnd.github.v3+json" \
      "/repos/$ORG/$repo/branches/$branch/protection" \
      --input protection.json > /tmp/output.log 2>> /tmp/error.log || {
      ERROR_MSG=$(cat /tmp/error.log)
      if echo "$ERROR_MSG" | grep -q "404"; then
        echo "❌ $ORG/$repo/$branch not found or not protected"
      elif echo "$ERROR_MSG" | grep -q "403"; then
        echo "❌ Permission denied for $ORG/$repo/$branch. Check token scopes."
      else
        echo "❌ Failed to protect $ORG/$repo/$branch: $ERROR_MSG"
      fi
      continue
    }
    echo "✅ Successfully protected $ORG/$repo/$branch"
    sleep 1  # Add delay to avoid rate limiting
  done
done

echo "Finished processing all repositories."
