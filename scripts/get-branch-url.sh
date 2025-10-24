#!/bin/bash
# Get the latest deployment URL for a specific branch

BRANCH_NAME="${1:-$(git branch --show-current)}"
PROJECT_NAME="graph-easy"

echo "🔍 Finding latest deployment for branch: $BRANCH_NAME"
echo ""

# Get deployments and find the first non-failed one for our branch
DEPLOYMENT_URL=$(npx wrangler pages deployment list --project-name="$PROJECT_NAME" 2>&1 | \
  grep "$BRANCH_NAME" | \
  grep -v "Failure" | \
  head -1 | \
  grep -o 'https://[a-z0-9]*\.graph-easy\.pages\.dev')

if [ -z "$DEPLOYMENT_URL" ]; then
  echo "❌ No successful deployment found for branch: $BRANCH_NAME"
  echo "💡 Tip: Make sure you've pushed commits to this branch"
  exit 1
fi

echo "✅ Latest deployment URL:"
echo "$DEPLOYMENT_URL"
echo ""
echo "🚀 You can use this URL - it will show the latest deployment for this branch"
