#!/usr/bin/env bash
set -euo pipefail

root_dir="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${root_dir}" ]]; then
  echo "ERROR: Run this script inside a git repository." >&2
  exit 1
fi

cd "${root_dir}"

bash scripts/setup-ghc/verify_ghc_commit.sh
./scripts/apply_patches.sh

if [[ -n "${TEST_CMD:-}" ]]; then
  echo "[run] Executing TEST_CMD."
  bash -lc "${TEST_CMD}"
  exit 0
fi

if [[ -x "vendor/ghc/hadrian/build-cabal" ]]; then
  echo "[run] Hadrian test stub (build-cabal --help)."
  (
    cd "vendor/ghc"
    ./hadrian/build-cabal --help >/dev/null
  )
  echo "[done] Minimal test stub passed."
  echo "[next] For full tests, set TEST_CMD. Example:"
  echo "       TEST_CMD='cd vendor/ghc && ./hadrian/build-cabal test --flavour=quick' scripts/test.sh"
  exit 0
fi

echo "[warn] No default tests configured."
echo "[done] verify_ghc_commit + apply_patches completed."
