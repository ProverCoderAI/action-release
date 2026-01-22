# ProverCoderAI Release Action

A GitHub Action for automated releases with changeset management, version bumping, npm/GitHub Packages publishing, and GitHub Release creation.

> **Note**: For initial setup instructions and tag creation, see [SETUP.md](SETUP.md)

## Features

- 🔄 Automatic version bumping using changesets
- 📦 Publish to npm registry
- 📦 Publish to GitHub Packages
- 🏷️ Automatic git tagging
- 📝 GitHub Release creation with auto-generated notes
- 📚 README copying to package directory
- 🔒 Secure token handling

## Usage

### Basic Example

```yaml
name: Release
on:
  workflow_run:
    workflows: ["Check"]
    branches: [main]
    types: [completed]

permissions:
  contents: write
  id-token: write
  pull-requests: write
  packages: write

jobs:
  release:
    if: github.event.workflow_run.conclusion == 'success'
    runs-on: ubuntu-latest
    steps:
      - uses: ProverCoderAI/action-release@v1
        with:
          ref: ${{ github.event.workflow_run.head_sha }}
          branch: ${{ github.event.workflow_run.head_branch }}
          package_json_path: packages/app/package.json
          pnpm_filter: ./packages/app
          bump_type: patch
          publish_npm: true
          publish_github_packages: true
          npm_token: ${{ secrets.NPM_TOKEN }}
          github_token: ${{ secrets.GITHUB_TOKEN }}
```

### Conversion from Reusable Workflow

If you previously used the reusable workflow format:

**Before:**
```yaml
jobs:
  release:
    uses: ./.github/workflows/release.yml
    with:
      ref: ${{ github.event.workflow_run.head_sha }}
      branch: ${{ github.event.workflow_run.head_branch }}
      package_json_path: packages/app/package.json
    secrets: inherit
```

**After:**
```yaml
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: ProverCoderAI/action-release@v1
        with:
          ref: ${{ github.event.workflow_run.head_sha }}
          branch: ${{ github.event.workflow_run.head_branch }}
          package_json_path: packages/app/package.json
          github_token: ${{ secrets.GITHUB_TOKEN }}
          npm_token: ${{ secrets.NPM_TOKEN }}
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `ref` | Git ref/sha to checkout | Yes | - |
| `branch` | Branch to push back version bump commit | No | `main` |
| `package_json_path` | Path to package.json of the published package | No | `packages/app/package.json` |
| `pnpm_filter` | pnpm --filter target (workspace package selector) | No | `./packages/app` |
| `bump_type` | Changeset bump type: patch/minor/major | No | `patch` |
| `tag_prefix` | Git tag prefix | No | `v` |
| `node_version` | Node.js version to use | No | `24` |
| `copy_readme` | Whether to copy README to package directory | No | `true` |
| `readme_source` | Source path for README | No | `README.md` |
| `readme_dest` | Destination path for README | No | `packages/app/README.md` |
| `publish_npm` | Whether to publish to npm registry | No | `true` |
| `publish_github_packages` | Whether to publish to GitHub Packages | No | `true` |
| `npm_token` | NPM authentication token | No (required if `publish_npm` is true) | - |
| `github_token` | GitHub token for releases and packages | Yes | - |

## Outputs

| Output | Description |
|--------|-------------|
| `version` | The version that was released |
| `tag` | The git tag that was created |

## How It Works

1. **Checkout**: Checks out the repository at the specified ref
2. **Setup**: Configures pnpm and Node.js environment
3. **Dependencies**: Installs project dependencies
4. **Changeset**: Creates automatic changeset if none exists
5. **Version**: Bumps package version using changesets
6. **Commit**: Commits version changes back to the branch
7. **Tag**: Creates and pushes git tag
8. **Build**: Builds the package distribution
9. **Publish**: Publishes to npm and/or GitHub Packages
10. **Release**: Creates GitHub Release with auto-generated notes

## Requirements

- The repository must use [changesets](https://github.com/changesets/changesets) for version management
- pnpm as package manager
- Node.js project with package.json

## Permissions

The workflow requires these permissions:

```yaml
permissions:
  contents: write        # For pushing commits and tags
  id-token: write       # For npm provenance
  pull-requests: write  # For changesets PR management
  packages: write       # For GitHub Packages publishing
```

## Examples

### Publish only to npm

```yaml
- uses: ProverCoderAI/action-release@v1
  with:
    ref: ${{ github.sha }}
    publish_npm: true
    publish_github_packages: false
    npm_token: ${{ secrets.NPM_TOKEN }}
    github_token: ${{ secrets.GITHUB_TOKEN }}
```

### Custom version bump type

```yaml
- uses: ProverCoderAI/action-release@v1
  with:
    ref: ${{ github.sha }}
    bump_type: minor  # or 'major'
    github_token: ${{ secrets.GITHUB_TOKEN }}
```

### Different Node.js version

```yaml
- uses: ProverCoderAI/action-release@v1
  with:
    ref: ${{ github.sha }}
    node_version: "20"
    github_token: ${{ secrets.GITHUB_TOKEN }}
```

## Deployment and Versioning

This action uses Git tags for versioning. Users reference the action using tag names:

- `ProverCoderAI/action-release@v1` - Latest v1.x.x release (recommended for auto-updates)
- `ProverCoderAI/action-release@v1.0.0` - Pinned to specific version (for stability)

### For Maintainers

After merging changes to main:

1. Use the provided script to create release tags:
   ```bash
   ./scripts/create-release-tag.sh 1.0.0
   ```

2. Or manually create tags:
   ```bash
   git tag -a v1.0.0 -m "v1.0.0 - Release description"
   git push origin v1.0.0

   # Update major version pointer
   git tag -fa v1 -m "v1 - Points to latest v1.x.x"
   git push origin v1 --force
   ```

See [SETUP.md](SETUP.md) for detailed setup and deployment instructions.

## License

MIT
