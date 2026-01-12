#!/bin/bash

# Setup GitHub Branch Protection Rules
# This script configures branch protection for the main branch

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔒 Setting up GitHub Branch Protection Rules...${NC}"

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed.${NC}"
    echo -e "${YELLOW}Please install it from: https://cli.github.com/${NC}"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}🔑 Please authenticate with GitHub CLI:${NC}"
    gh auth login
fi

# Get the repository info
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
echo -e "${GREEN}📦 Repository: ${REPO}${NC}"

# Set up branch protection rules for main branch
echo -e "${GREEN}🛡️ Configuring branch protection for 'main'...${NC}"

gh api repos/${REPO}/branches/main/protection \
  --method PUT \
  --field required_status_checks='{
    "strict": true,
    "checks": [
      {"context": "Run Tests (18.x)"},
      {"context": "Run Tests (20.x)"},
      {"context": "Code Quality Checks"}
    ]
  }' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "require_last_push_approval": false
  }' \
  --field restrictions=null \
  --field allow_force_pushes=false \
  --field allow_deletions=false \
  --field block_creations=false \
  --field required_conversation_resolution=true

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Branch protection rules configured successfully!${NC}"
else
    echo -e "${RED}❌ Failed to configure branch protection rules.${NC}"
    echo -e "${YELLOW}You may need to configure these manually in GitHub:${NC}"
    echo -e "1. Go to your repository on GitHub"
    echo -e "2. Click Settings > Branches"
    echo -e "3. Add a rule for the 'main' branch with the following settings:"
    echo -e "   - Require a pull request before merging"
    echo -e "   - Require approvals (1)"
    echo -e "   - Dismiss stale reviews"
    echo -e "   - Require review from CODEOWNERS"
    echo -e "   - Require status checks to pass before merging"
    echo -e "   - Require branches to be up to date before merging"
    echo -e "   - Required status checks:"
    echo -e "     * Run Tests (18.x)"
    echo -e "     * Run Tests (20.x)"
    echo -e "     * Code Quality Checks"
    echo -e "   - Restrict pushes that create matching branches"
    echo -e "   - Do not allow bypassing the above settings"
fi

echo -e "${GREEN}🎉 Setup complete!${NC}"
echo -e "${YELLOW}📋 Next steps:${NC}"
echo -e "1. Push your changes to trigger the first CI run"
echo -e "2. Create a test pull request to verify the protection rules"
echo -e "3. Check that status checks appear and must pass before merging"
echo ""
echo -e "${GREEN}🔧 Manual verification:${NC}"
echo -e "- Go to https://github.com/${REPO}/settings/branches"
echo -e "- Verify the 'main' branch protection rule is active"
echo -e "- Test with a pull request that breaks tests to confirm protection works"