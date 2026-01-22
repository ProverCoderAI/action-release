# Test Action Usage

This directory contains a test to verify that the action can be referenced correctly.

## Test Result

✅ Action is properly configured and can be referenced as:
- `konard/ProverCoderAI-action-release@v1` (from fork with tags)
- `ProverCoderAI/action-release@v1` (after tags are created in upstream)

## Tags Created

Tags have been created in the fork repository:
- v1.0.0 - Initial release tag
- v1 - Floating tag pointing to latest v1.x.x

## Next Steps

After PR is merged to main, tags should be created in the upstream repository:

```bash
# On main branch after merge
git checkout main
git pull origin main
git tag -a v1.0.0 -m "v1.0.0 - Initial release of ProverCoderAI Release Action"
git tag -a v1 -m "v1 - Points to latest v1.x.x release"
git push origin v1.0.0 v1
```

## Verification

The action metadata has been validated and is ready for use. See the workflow validation results in CI.
