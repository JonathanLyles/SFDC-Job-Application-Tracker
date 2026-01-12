# Setup GitHub Branch Protection Rules (PowerShell)
# This script configures branch protection for the main branch

Write-Host "🔒 Setting up GitHub Branch Protection Rules..." -ForegroundColor Green

# Check if GitHub CLI is installed
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "❌ GitHub CLI (gh) is not installed." -ForegroundColor Red
    Write-Host "Please install it from: https://cli.github.com/" -ForegroundColor Yellow
    exit 1
}

# Check if user is authenticated
$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "🔑 Please authenticate with GitHub CLI:" -ForegroundColor Yellow
    gh auth login
}

# Get the repository info
$repo = gh repo view --json nameWithOwner --jq '.nameWithOwner'
Write-Host "📦 Repository: $repo" -ForegroundColor Green

# Set up branch protection rules for main branch
Write-Host "🛡️ Configuring branch protection for 'main'..." -ForegroundColor Green

$protectionConfig = @{
    required_status_checks = @{
        strict = $true
        checks = @(
            @{ context = "Run Tests (18.x)" },
            @{ context = "Run Tests (20.x)" },
            @{ context = "Code Quality Checks" }
        )
    }
    enforce_admins = $true
    required_pull_request_reviews = @{
        required_approving_review_count = 1
        dismiss_stale_reviews = $true
        require_code_owner_reviews = $true
        require_last_push_approval = $false
    }
    restrictions = $null
    allow_force_pushes = $false
    allow_deletions = $false
    block_creations = $false
    required_conversation_resolution = $true
} | ConvertTo-Json -Depth 10

try {
    $result = gh api "repos/$repo/branches/main/protection" --method PUT --input - <<< $protectionConfig
    Write-Host "✅ Branch protection rules configured successfully!" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to configure branch protection rules." -ForegroundColor Red
    Write-Host "You may need to configure these manually in GitHub:" -ForegroundColor Yellow
    Write-Host "1. Go to your repository on GitHub"
    Write-Host "2. Click Settings > Branches"
    Write-Host "3. Add a rule for the 'main' branch with the following settings:"
    Write-Host "   - Require a pull request before merging"
    Write-Host "   - Require approvals (1)"
    Write-Host "   - Dismiss stale reviews"
    Write-Host "   - Require review from CODEOWNERS"
    Write-Host "   - Require status checks to pass before merging"
    Write-Host "   - Require branches to be up to date before merging"
    Write-Host "   - Required status checks:"
    Write-Host "     * Run Tests (18.x)"
    Write-Host "     * Run Tests (20.x)"
    Write-Host "     * Code Quality Checks"
    Write-Host "   - Restrict pushes that create matching branches"
    Write-Host "   - Do not allow bypassing the above settings"
}

Write-Host "🎉 Setup complete!" -ForegroundColor Green
Write-Host "📋 Next steps:" -ForegroundColor Yellow
Write-Host "1. Push your changes to trigger the first CI run"
Write-Host "2. Create a test pull request to verify the protection rules"
Write-Host "3. Check that status checks appear and must pass before merging"
Write-Host ""
Write-Host "🔧 Manual verification:" -ForegroundColor Green
Write-Host "- Go to https://github.com/$repo/settings/branches"
Write-Host "- Verify the 'main' branch protection rule is active"
Write-Host "- Test with a pull request that breaks tests to confirm protection works"