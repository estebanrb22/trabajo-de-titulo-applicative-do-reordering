#!/usr/bin/env bash
set -euo pipefail

PATCH_DIR="${PATCH_DIR:-patches}"
TARGET_DIR="${TARGET_DIR:-vendor/ghc}"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

root_dir="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "${root_dir}" ]] || die "Run this script inside a git repository."

cd "${root_dir}"

git -C "${TARGET_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || die "${TARGET_DIR} is not an initialized git repository/submodule."

if [[ ! -d "${PATCH_DIR}" ]]; then
  echo "[info] ${PATCH_DIR}/ does not exist. Nothing to apply."
  exit 0
fi

shopt -s nullglob
patch_files=("${PATCH_DIR}"/*.patch)
shopt -u nullglob

if (( ${#patch_files[@]} == 0 )); then
  echo "[info] No patch files found in ${PATCH_DIR}/."
  exit 0
fi

mapfile -t patch_files < <(printf '%s\n' "${patch_files[@]}" | LC_ALL=C sort)

applied_count=0
skipped_count=0

for patch in "${patch_files[@]}"; do
  patch_path="${root_dir}/${patch}"
  echo "[run] Processing ${patch}"

  if git -C "${TARGET_DIR}" apply --check "${patch_path}" >/dev/null 2>&1; then
    git -C "${TARGET_DIR}" apply "${patch_path}"
    echo "[ok] Applied ${patch}"
    applied_count=$((applied_count + 1))
    continue
  fi

  if git -C "${TARGET_DIR}" apply --reverse --check "${patch_path}" >/dev/null 2>&1; then
    echo "[skip] Already applied: ${patch}"
    skipped_count=$((skipped_count + 1))
    continue
  fi

  die "Patch failed and does not look already applied: ${patch}"
done

echo "[done] Patch processing complete. applied=${applied_count}, skipped=${skipped_count}"
