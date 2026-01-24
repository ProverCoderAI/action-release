#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: compare-npm-tarballs.sh [options]

Compares the local npm tarball (after optional dist-deps-prune) with the latest
published tarball for the package.

Options:
  --package <path>    Path to package.json (default: packages/app/package.json)
  --dist <path>       Path to dist directory override (optional)
  --build <cmd>       Build command to run before compare (optional)
  --readme-source <p> Source README to copy before compare (optional)
  --readme-dest <p>   Destination README path to copy to (optional)
  --prune-dev <bool>  Whether to prune devDependencies (default: true)
  --npm-token <tok>   npm token for private packages (optional)
  --show-diff         Show unified diff for differing files
  -h, --help          Show this help
USAGE
}

PKG_PATH="packages/app/package.json"
DIST_PATH=""
DIST_PATH_SET="false"
BUILD_CMD=""
README_SOURCE=""
README_DEST=""
PRUNE_DEV="true"
NPM_TOKEN=""
SHOW_DIFF="false"

while [ $# -gt 0 ]; do
  case "$1" in
    --package)
      PKG_PATH="$2"
      shift 2
      ;;
    --dist)
      DIST_PATH="$2"
      DIST_PATH_SET="true"
      shift 2
      ;;
    --build)
      BUILD_CMD="$2"
      shift 2
      ;;
    --readme-source)
      README_SOURCE="$2"
      shift 2
      ;;
    --readme-dest)
      README_DEST="$2"
      shift 2
      ;;
    --prune-dev)
      PRUNE_DEV="$2"
      shift 2
      ;;
    --npm-token)
      NPM_TOKEN="$2"
      shift 2
      ;;
    --show-diff)
      SHOW_DIFF="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown аргумент: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
 done

for bin in node npm pnpm; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "Required command not found: $bin" >&2
    exit 1
  fi
 done

if [ ! -f "$PKG_PATH" ]; then
  echo "package.json not found: $PKG_PATH" >&2
  exit 1
fi

PKG_DIR="$(dirname "$PKG_PATH")"

if [ -n "$BUILD_CMD" ]; then
  echo "> Running build: $BUILD_CMD"
  bash -lc "$BUILD_CMD"
fi

if [ "$DIST_PATH_SET" = "true" ] && [ ! -d "$DIST_PATH" ]; then
  echo "dist directory not found: $DIST_PATH" >&2
  exit 1
fi

PKG_NAME="$(node -p "require('./${PKG_PATH}').name")"

if [ -n "$NPM_TOKEN" ]; then
  printf '%s\n' "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" > "$HOME/.npmrc"
fi

LATEST_VERSION="$(npm view "${PKG_NAME}" version 2>/dev/null || true)"
if [ -z "$LATEST_VERSION" ]; then
  echo "Unable to resolve latest version for ${PKG_NAME}" >&2
  exit 1
fi

echo "> Package: ${PKG_NAME}@${LATEST_VERSION}"

TMP_DIR="$(mktemp -d)"
LOCAL_PACK_DIR="${TMP_DIR}/local-pack"
REMOTE_PACK_DIR="${TMP_DIR}/remote-pack"
LOCAL_DIR="${TMP_DIR}/local"
REMOTE_DIR="${TMP_DIR}/remote"
BACKUP_PKG="${PKG_DIR}/.package.json.release.bak"
README_BACKUP=""
README_CREATED="false"

cleanup() {
  if [ -f "$BACKUP_PKG" ]; then
    cp "$BACKUP_PKG" "$PKG_PATH" || true
    rm -f "$BACKUP_PKG" || true
  fi
  if [ -n "$README_DEST" ]; then
    if [ -n "$README_BACKUP" ] && [ -f "$README_BACKUP" ]; then
      cp "$README_BACKUP" "$README_DEST" || true
      rm -f "$README_BACKUP" || true
    elif [ "$README_CREATED" = "true" ] && [ -f "$README_DEST" ]; then
      rm -f "$README_DEST" || true
    fi
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$LOCAL_PACK_DIR" "$REMOTE_PACK_DIR" "$LOCAL_DIR" "$REMOTE_DIR"

REMOTE_TARBALL="$(npm pack "${PKG_NAME}@${LATEST_VERSION}" --silent --pack-destination "$REMOTE_PACK_DIR" 2>/dev/null | tail -n 1)"
REMOTE_TAR_PATH="$REMOTE_PACK_DIR/$REMOTE_TARBALL"
if [ ! -f "$REMOTE_TAR_PATH" ]; then
  echo "Unable to download ${PKG_NAME}@${LATEST_VERSION}" >&2
  exit 1
fi

if [ -n "$README_SOURCE" ] || [ -n "$README_DEST" ]; then
  if [ -z "$README_SOURCE" ] || [ -z "$README_DEST" ]; then
    echo "Both --readme-source and --readme-dest are required together" >&2
    exit 1
  fi
  if [ ! -f "$README_SOURCE" ]; then
    echo "README source not found: $README_SOURCE" >&2
    exit 1
  fi
  if [ -f "$README_DEST" ]; then
    README_BACKUP="${TMP_DIR}/README.backup"
    cp "$README_DEST" "$README_BACKUP"
  else
    README_CREATED="true"
  fi
  mkdir -p "$(dirname "$README_DEST")"
  cp "$README_SOURCE" "$README_DEST"
fi

cp "$PKG_PATH" "$BACKUP_PKG"

PRUNE_DIST_ARGS=()
if [ "$DIST_PATH_SET" = "true" ]; then
  PRUNE_DIST_ARGS=(--dist "$DIST_PATH")
fi

pnpm dlx @prover-coder-ai/dist-deps-prune apply \
  "${PRUNE_DIST_ARGS[@]}" \
  --package "$PKG_PATH" \
  --prune-dev "$PRUNE_DEV" \
  --write \
  --silent

LOCAL_PACK_OUT="$(cd "$PKG_DIR" && pnpm pack --pack-destination "$LOCAL_PACK_DIR" 2>/dev/null || true)"
LOCAL_TARBALL="$(printf '%s' "$LOCAL_PACK_OUT" | tail -n 1)"
LOCAL_TAR_PATH="$LOCAL_TARBALL"
if [ ! -f "$LOCAL_TAR_PATH" ]; then
  LOCAL_TAR_PATH="$LOCAL_PACK_DIR/$LOCAL_TARBALL"
fi
if [ ! -f "$LOCAL_TAR_PATH" ]; then
  echo "Unable to pack local ${PKG_NAME}" >&2
  exit 1
fi

cp "$BACKUP_PKG" "$PKG_PATH"
rm -f "$BACKUP_PKG"

 tar -xzf "$LOCAL_TAR_PATH" -C "$LOCAL_DIR"
 tar -xzf "$REMOTE_TAR_PATH" -C "$REMOTE_DIR"

LOCAL_PKG="${LOCAL_DIR}/package/package.json"
REMOTE_PKG="${REMOTE_DIR}/package/package.json"

if [ ! -f "$LOCAL_PKG" ] || [ ! -f "$REMOTE_PKG" ]; then
  echo "package.json missing in tarball" >&2
  exit 1
fi

node -e "const fs=require('fs');const p=process.argv[1];const sort=(v)=>Array.isArray(v)?v.map(sort):v&&typeof v==='object'?Object.keys(v).sort().reduce((acc,k)=>{acc[k]=sort(v[k]);return acc;},{}):v;const pkg=JSON.parse(fs.readFileSync(p,'utf8'));delete pkg.gitHead;pkg.version='0.0.0';const norm=sort(pkg);fs.writeFileSync(p, JSON.stringify(norm, null, 2)+'\\n');" "$LOCAL_PKG"
node -e "const fs=require('fs');const p=process.argv[1];const sort=(v)=>Array.isArray(v)?v.map(sort):v&&typeof v==='object'?Object.keys(v).sort().reduce((acc,k)=>{acc[k]=sort(v[k]);return acc;},{}):v;const pkg=JSON.parse(fs.readFileSync(p,'utf8'));delete pkg.gitHead;pkg.version='0.0.0';const norm=sort(pkg);fs.writeFileSync(p, JSON.stringify(norm, null, 2)+'\\n');" "$REMOTE_PKG"

if diff -qr "$LOCAL_DIR/package" "$REMOTE_DIR/package" >/dev/null 2>&1; then
  echo "RESULT: identical"
  exit 0
fi

echo "RESULT: different"
if [ "$SHOW_DIFF" = "true" ]; then
  diff -ru "$LOCAL_DIR/package" "$REMOTE_DIR/package" || true
else
  diff -qr "$LOCAL_DIR/package" "$REMOTE_DIR/package" || true
fi
exit 1
