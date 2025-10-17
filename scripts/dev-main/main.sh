#!/bin/bash

# Usage: ./create_prs.sh <github_token>

GH_TOKEN="$1"
if [ -z "$GH_TOKEN" ]; then
  echo "Error: GitHub token required as first argument."
  exit 1
fi

ORG="scott45"
REPOS_FILE="repos.txt"

if [ ! -f "$REPOS_FILE" ]; then
  echo "Error: $REPOS_FILE not found."
  exit 1
fi

TITLE="feat!: New Major Release"
ASSIGNEE="scott45"
REVIEWERS=""
BODY="# SPDX-License-Identifier: Apache-2.0

## What did we change?
- Change exposed docker port for the service Create New Major Release

## How was it tested?
- [ ] Locally
- [x] Development Environment
- [ ] Not needed, changes very basic
- [ ] Husky successfully run
- [ ] Unit tests passing and Documentation done"

for REPO_NAME in $(cat "$REPOS_FILE"); do
  REPO="${ORG}/${REPO_NAME}"
  echo "Processing repository: $REPO"

  # Check for existing PR
  PR_NUMBER=$(gh pr list --head dev --base main --json number --jq '.[0].number // ""' --repo "$REPO")

  if [ -z "$PR_NUMBER" ]; then
    echo "No existing PR found. Creating new PR."

    # Check and collect labels using gh api
    LABELS=()
    for LABEL in build enhancement CICD; do
      if gh api repos/"$REPO"/labels --jq '.[].name' | grep -q "^$LABEL$"; then
        LABELS+=("$LABEL")
      fi
    done
    LABEL_ARGS=""
    if [ ${#LABELS[@]} -gt 0 ]; then
      LABEL_ARGS="--label $(IFS=','; echo "${LABELS[*]}")"
    fi

    # Create PR using gh CLI
    gh pr create --repo "$REPO" --base main --head dev --title "$TITLE" --body "$BODY" --assignee "$ASSIGNEE" --reviewer "$REVIEWERS" $LABEL_ARGS
    echo "✅ PR created for $REPO"
  else
    echo "Existing PR found (#$PR_NUMBER) in $REPO. No new PR created."
  fi
done

echo "Finished processing all repositories."
