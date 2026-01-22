#!/bin/bash
# Script to create and push release tags for the action
# Usage: ./scripts/create-release-tag.sh [version]
# Example: ./scripts/create-release-tag.sh 1.0.0

set -euo pipefail

VERSION="${1:-}"

if [ -z "$VERSION" ]; then
  echo "Error: Version number required"
  echo "Usage: $0 <version>"
  echo "Example: $0 1.0.0"
  exit 1
fi

# Validate version format (basic semver check)
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: Version must be in semver format (e.g., 1.0.0)"
  exit 1
fi

# Extract major version
MAJOR_VERSION="v${VERSION%%.*}"
FULL_VERSION="v${VERSION}"

echo "Creating release tags for version ${VERSION}"
echo "- Full version tag: ${FULL_VERSION}"
echo "- Major version tag: ${MAJOR_VERSION}"
echo ""

# Ensure we're on the main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
  echo "Warning: You are on branch '${CURRENT_BRANCH}', not 'main'"
  read -p "Continue anyway? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Check for uncommitted changes
if ! git diff --quiet || ! git diff --staged --quiet; then
  echo "Error: You have uncommitted changes. Please commit or stash them first."
  exit 1
fi

# Create semantic version tag
echo "Creating tag ${FULL_VERSION}..."
git tag -a "$FULL_VERSION" -m "${FULL_VERSION} - Release of ProverCoderAI Release Action"

# Update major version tag
if git rev-parse "$MAJOR_VERSION" >/dev/null 2>&1; then
  echo "Updating existing major version tag ${MAJOR_VERSION}..."
  git tag -fa "$MAJOR_VERSION" -m "${MAJOR_VERSION} - Points to latest ${MAJOR_VERSION}.x.x release (${FULL_VERSION})"
else
  echo "Creating major version tag ${MAJOR_VERSION}..."
  git tag -a "$MAJOR_VERSION" -m "${MAJOR_VERSION} - Points to latest ${MAJOR_VERSION}.x.x release (${FULL_VERSION})"
fi

echo ""
echo "Tags created successfully:"
git tag -n1 | grep -E "^${FULL_VERSION}|^${MAJOR_VERSION}"
echo ""

read -p "Push tags to origin? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Pushing tags to origin..."
  git push origin "$FULL_VERSION"
  git push origin "$MAJOR_VERSION" --force
  echo ""
  echo "✓ Tags pushed successfully!"
  echo ""
  echo "Next steps:"
  echo "1. Create a GitHub Release at: https://github.com/ProverCoderAI/action-release/releases/new?tag=${FULL_VERSION}"
  echo "2. Users can now reference the action with: ProverCoderAI/action-release@${MAJOR_VERSION}"
  echo "3. For pinned version: ProverCoderAI/action-release@${FULL_VERSION}"
else
  echo "Tags created locally but not pushed."
  echo "To push later, run:"
  echo "  git push origin $FULL_VERSION"
  echo "  git push origin $MAJOR_VERSION --force"
fi
