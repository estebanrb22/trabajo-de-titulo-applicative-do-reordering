#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGE_FILE="${SCRIPT_DIR}/cachyos-packages.txt"
readonly VERIFY_SCRIPT="${SCRIPT_DIR}/verify.sh"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

usage() {
  echo "Usage: bash scripts/setup-latex/install-cachyos.sh"
}

if (( $# > 0 )); then
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
  fi
  usage >&2
  exit 2
fi

command -v pacman >/dev/null 2>&1 || die "pacman was not found. This installer requires CachyOS or another Arch-based distribution."
[[ -r "${PACKAGE_FILE}" ]] || die "Package manifest not found: ${PACKAGE_FILE}"
[[ -r "${VERIFY_SCRIPT}" ]] || die "Verification script not found: ${VERIFY_SCRIPT}"

packages=()
while IFS= read -r package || [[ -n "${package}" ]]; do
  package="${package%%#*}"
  package="${package#"${package%%[![:space:]]*}"}"
  package="${package%"${package##*[![:space:]]}"}"
  [[ -z "${package}" ]] && continue
  [[ "${package}" =~ ^[a-z0-9@._+-]+$ ]] || die "Invalid package name in ${PACKAGE_FILE}: ${package}"
  packages+=("${package}")
done < "${PACKAGE_FILE}"

(( ${#packages[@]} > 0 )) || die "Package manifest is empty: ${PACKAGE_FILE}"

pacman_cmd=(pacman)
if (( EUID != 0 )); then
  command -v sudo >/dev/null 2>&1 || die "sudo is required when the installer is not run as root."
  pacman_cmd=(sudo pacman)
fi

echo "[run] Updating CachyOS and installing the LaTeX toolchain."
printf '  %s\n' "${packages[@]}"
"${pacman_cmd[@]}" -Syu --needed -- "${packages[@]}"

echo "[run] Verifying the LaTeX installation."
bash "${VERIFY_SCRIPT}"

echo "[done] The LaTeX toolchain required by reports/informe is installed."
