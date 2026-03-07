#!/usr/bin/env bash
set -euo pipefail

root_dir="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${root_dir}" ]]; then
  echo "ERROR: Run this script inside a git repository." >&2
  exit 1
fi

cd "${root_dir}"

if [[ -n "${BUILD_CMD:-}" ]]; then
  echo "[run] Executing BUILD_CMD."
  bash -lc "${BUILD_CMD}"
  exit 0
fi

if [[ -x "vendor/ghc/hadrian/build-cabal" ]]; then
  echo "[run] Hadrian smoke check (build-cabal --help)."
  (
    cd "vendor/ghc"
    ./hadrian/build-cabal --help >/dev/null
  )
  echo "[done] Minimal build check passed."
  echo "[next] For full build, set BUILD_CMD. Example:"
  echo "       BUILD_CMD='cd vendor/ghc && ./hadrian/build-cabal -j' scripts/build.sh"
  exit 0
fi

echo "[warn] No default build command configured."
echo "[next] Set BUILD_CMD with your project-specific build command."
