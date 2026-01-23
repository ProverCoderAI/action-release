# Setup Guide for ProverCoderAI Release Action

This guide explains how to make the action fully functional and ready for use in other repositories.

## Current Status

✅ **action.yml** - Correctly structured as a composite action
✅ **Repository visibility** - Public (accessible to all)
✅ **Action dependencies** - Using valid versions (actions/checkout@v6, actions/setup-node@v6)
✅ **README** - Comprehensive documentation with examples
⚠️ **Git tag** - v1 tag needs to be created in the main repository

## What's Already Working

The action has been successfully converted from a reusable workflow to a composite action. All the code is in place and the structure follows GitHub's requirements for composite actions.

## Required Steps to Enable the Action

### 1. Create and Push v1 Tag

After merging this PR to the main branch, create a git tag pointing to the merge commit:

```bash
# Switch to main branch
git checkout main

# Pull latest changes
git pull origin main

# Create annotated tag v1
git tag -a v1 -m "v1 - Initial release of ProverCoderAI Release Action"

# Push the tag to the repository
git push origin v1
```

Alternatively, use GitHub CLI:

```bash
# Create a release with tag v1
gh release create v1 --title "v1 - Initial Release" --notes "Initial release of ProverCoderAI Release Action as a composite action" --target main
```

### 2. Create Semantic Version Tags (Recommended)

For better version management, also create semantic version tags:

```bash
# Create v1.0.0 tag
git tag -a v1.0.0 -m "v1.0.0 - Initial release"
git push origin v1.0.0

# Update v1 to point to v1.0.0
git tag -fa v1 -m "v1 - Points to latest v1.x.x release"
git push origin v1 --force
```

### 3. Verify the Action is Accessible

Test that other repositories can use the action:

```yaml
# In another repository's workflow
- uses: ProverCoderAI/action-release@v1.0.6
  with:
    ref: ${{ github.sha }}
    github_token: ${{ secrets.GITHUB_TOKEN }}
```

## For Private Repositories (Not Applicable - This Repo is Public)

If the repository were private, you would need to:

1. Go to **Settings → Actions → General → Access**
2. Select "Accessible from repositories in the organization" or specify allowed repositories

## For Users of This Action

### Required Permissions

Workflows using this action must have these permissions:

```yaml
permissions:
  contents: write        # For pushing commits and tags
  id-token: write       # For npm provenance
  pull-requests: write  # For changesets PR management
  packages: write       # For GitHub Packages publishing
```

### Required Secrets

- `GITHUB_TOKEN` - Automatically provided by GitHub Actions
- `NPM_TOKEN` - Required if publishing to npm (optional)

### Optional Behavior

- `skip_if_unchanged` - When enabled, the action compares the local npm tarball with the latest published tarball (ignoring version/gitHead) and skips the release if identical. For private npm packages, provide `NPM_TOKEN` so the comparison can fetch the published tarball.

### Action Permissions Policy

Ensure your repository allows this action:

1. Go to **Settings → Actions → General → Actions permissions**
2. Select "Allow all actions and reusable workflows" or add this action to the allow list

## Testing

An example workflow is provided in `.github/workflows/test-action.yml` that demonstrates how to use the action.

## Version Management Strategy

### Major Version Tags (v1, v2, etc.)

- Create major version tags (v1, v2) that "float" to the latest release in that major version
- Users reference these for automatic minor/patch updates: `ProverCoderAI/action-release@v1`

### Semantic Version Tags (v1.0.0, v1.1.0, etc.)

- Create specific semantic version tags for each release
- Users can pin to specific versions for stability: `ProverCoderAI/action-release@v1.0.0`

### When to Update Tags

**After each release:**
1. Create a new semantic version tag (e.g., v1.1.0)
2. Update the major version tag (v1) to point to the new release

```bash
# Example for v1.1.0 release
git tag -a v1.1.0 -m "v1.1.0 - Description of changes"
git push origin v1.1.0

# Update v1 to point to v1.1.0
git tag -fa v1 -m "v1 - Points to latest v1.x.x release"
git push origin v1 --force
```

## Troubleshooting

### "Action not found" Error

- Verify the v1 tag exists: `git ls-remote --tags https://github.com/ProverCoderAI/action-release`
- Check repository visibility is public
- Ensure the calling repository allows external actions

### Permission Errors

- Verify the workflow has all required permissions listed above
- Check that secrets are properly configured

### Build/Publish Failures

- Review the action logs for specific error messages
- Ensure the repository structure matches expected paths (package.json, pnpm workspace, etc.)

## References

- [GitHub Docs: Creating a composite action](https://docs.github.com/actions/creating-actions/creating-a-composite-action)
- [GitHub Docs: Sharing actions from a private repository](https://docs.github.com/actions/creating-actions/sharing-actions-and-workflows-from-your-private-repository)
- [GitHub Docs: Managing GitHub Actions settings](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository)
