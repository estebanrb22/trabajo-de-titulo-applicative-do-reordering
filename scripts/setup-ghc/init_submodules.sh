#!/usr/bin/env bash
set -euo pipefail

readonly SUBMODULE_PATH="vendor/ghc"
readonly TARGET_COMMIT="0b36e96cb93db71f201aaa055c4a90b75a8110ef"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

has_non_submodule_tracked_changes() {
  ! git -C "${SUBMODULE_PATH}" diff --quiet --ignore-submodules=all \
    || ! git -C "${SUBMODULE_PATH}" diff --cached --quiet --ignore-submodules=all
}

cleanup_transition_artifacts() {
  if has_non_submodule_tracked_changes; then
    die "${SUBMODULE_PATH} has tracked local changes. Refusing automatic cleanup before checkout."
  fi

  git -C "${SUBMODULE_PATH}" submodule deinit -f --all || true
  git -C "${SUBMODULE_PATH}" clean -ffd
  git -C "${SUBMODULE_PATH}" clean -ffdX
}

root_dir="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${root_dir}" ]]; then
  echo "ERROR: Run this script inside a git repository." >&2
  exit 1
fi

cd "${root_dir}"

if [[ -e "${SUBMODULE_PATH}/.git" ]]; then
  echo "[ok] ${SUBMODULE_PATH} is already initialized."
else
  echo "[run] git submodule update --init ${SUBMODULE_PATH}"
  git submodule update --init "${SUBMODULE_PATH}"
fi

echo "[run] Pinning ${SUBMODULE_PATH} to ${TARGET_COMMIT}"
git -C "${SUBMODULE_PATH}" fetch --all --tags --prune

if ! git -C "${SUBMODULE_PATH}" checkout --detach "${TARGET_COMMIT}"; then
  echo "[warn] Checkout failed; cleaning nested submodule artifacts."
  cleanup_transition_artifacts
  git -C "${SUBMODULE_PATH}" checkout --detach "${TARGET_COMMIT}"
fi

if [[ "${INIT_GHC_NESTED_SUBMODULES:-0}" == "1" ]]; then
  echo "[run] INIT_GHC_NESTED_SUBMODULES=1: git -C ${SUBMODULE_PATH} submodule update --init --recursive"
  git -C "${SUBMODULE_PATH}" submodule sync --recursive
  git -C "${SUBMODULE_PATH}" submodule update --init --recursive
else
  # Keep a clean, non-recursive state unless explicitly requested.
  git -C "${SUBMODULE_PATH}" submodule deinit -f --all >/dev/null 2>&1 || true
fi

echo "[done] Submodules initialized."
git submodule status
