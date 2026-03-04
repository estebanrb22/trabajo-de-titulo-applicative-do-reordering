#!/usr/bin/env bash
set -euo pipefail

readonly SUBMODULE_URL="https://github.com/ghc/ghc.git"
readonly SUBMODULE_PATH="vendor/ghc"
readonly TARGET_COMMIT="8ecf6d8f7dfee9e5b1844cd196f83f00f3b6b879"

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

  echo "[warn] Checkout failed due working-tree conflicts; cleaning nested submodule artifacts."
  git -C "${SUBMODULE_PATH}" submodule deinit -f --all || true
  git -C "${SUBMODULE_PATH}" clean -ffd
  git -C "${SUBMODULE_PATH}" clean -ffdX
}

root_dir="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "${root_dir}" ]] || die "Run this script inside a git repository."

cd "${root_dir}"

is_indexed_submodule() {
  local mode
  mode="$(git ls-files --stage -- "${SUBMODULE_PATH}" | awk 'NR == 1 { print $1 }')"
  [[ "${mode}" == "160000" ]]
}

has_gitmodules_entry() {
  [[ -f .gitmodules ]] || return 1
  git config -f .gitmodules --get-regexp '^submodule\..*\.path$' 2>/dev/null \
    | awk '{ print $2 }' \
    | grep -Fxq "${SUBMODULE_PATH}"
}

if [[ -e "${SUBMODULE_PATH}" ]]; then
  if is_indexed_submodule; then
    echo "[ok] Existing submodule detected at ${SUBMODULE_PATH}."
  else
    die "'${SUBMODULE_PATH}' exists but is not a git submodule. Refusing to overwrite."
  fi
else
  if has_gitmodules_entry; then
    echo "[ok] .gitmodules already tracks ${SUBMODULE_PATH}. Reinitializing checkout."
  else
    echo "[run] Adding GHC submodule at ${SUBMODULE_PATH}."
    mkdir -p "$(dirname "${SUBMODULE_PATH}")"
    git submodule add "${SUBMODULE_URL}" "${SUBMODULE_PATH}"
  fi
fi

echo "[run] Initializing/updating submodules recursively."
git submodule update --init --recursive

echo "[run] Pinning ${SUBMODULE_PATH} to ${TARGET_COMMIT}."
git -C "${SUBMODULE_PATH}" fetch --all --tags --prune

current_commit="$(git -C "${SUBMODULE_PATH}" rev-parse HEAD)"
if [[ "${current_commit}" != "${TARGET_COMMIT}" ]]; then
  if ! git -C "${SUBMODULE_PATH}" checkout --detach "${TARGET_COMMIT}"; then
    cleanup_transition_artifacts
    git -C "${SUBMODULE_PATH}" checkout --detach "${TARGET_COMMIT}"
  fi
else
  echo "[ok] ${SUBMODULE_PATH} is already at ${TARGET_COMMIT}."
fi

current_commit="$(git -C "${SUBMODULE_PATH}" rev-parse HEAD)"
[[ "${current_commit}" == "${TARGET_COMMIT}" ]] || die "Submodule checkout failed. Current: ${current_commit}"

echo "[info] Superproject submodule pointer status:"
git status --short -- .gitmodules "${SUBMODULE_PATH}" || true

echo "[done] GHC submodule is ready."
echo "[next] Stage and commit manually:"
echo "       git add .gitmodules ${SUBMODULE_PATH}"
echo "       git commit -m \"Add GHC as submodule pinned to ApplicativeDo commit\""
