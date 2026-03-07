#!/usr/bin/env bash
set -euo pipefail

readonly SUBMODULE_PATH="vendor/ghc"
readonly EXPECTED_COMMIT="0b36e96cb93db71f201aaa055c4a90b75a8110ef"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

root_dir="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "${root_dir}" ]] || die "Run this script inside a git repository."

cd "${root_dir}"

mode="$(git ls-files --stage -- "${SUBMODULE_PATH}" | awk 'NR == 1 { print $1 }')"
[[ "${mode}" == "160000" ]] || die "${SUBMODULE_PATH} is not tracked as a git submodule."

if [[ ! -e "${SUBMODULE_PATH}/.git" ]]; then
  die "${SUBMODULE_PATH} is not initialized. Run scripts/setup-ghc/init_submodules.sh first."
fi

current_commit="$(git -C "${SUBMODULE_PATH}" rev-parse HEAD 2>/dev/null || true)"
[[ -n "${current_commit}" ]] || die "Cannot read current commit for ${SUBMODULE_PATH}."

if [[ "${current_commit}" != "${EXPECTED_COMMIT}" ]]; then
  echo "ERROR: ${SUBMODULE_PATH} is at ${current_commit}, expected ${EXPECTED_COMMIT}." >&2
  exit 2
fi

echo "[ok] ${SUBMODULE_PATH} is pinned to ${EXPECTED_COMMIT}."
