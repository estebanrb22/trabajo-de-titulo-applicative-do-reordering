#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGE_FILE="${SCRIPT_DIR}/cachyos-packages.txt"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: bash scripts/setup-latex/uninstall-cachyos.sh [options]

Options:
  -y, --yes              Skip the package-removal confirmation.
      --purge-user-data  Also remove ~/.texlive and ~/texmf.
  -h, --help             Show this help.
EOF
}

confirm() {
  local prompt="$1"
  local reply

  [[ -t 0 ]] || die "Interactive confirmation requires a terminal. Use --yes when appropriate."
  read -r -p "${prompt} [y/N] " reply
  [[ "${reply}" =~ ^[Yy]$ ]]
}

assume_yes=0
purge_user_data=0

while (( $# > 0 )); do
  case "$1" in
    -y|--yes)
      assume_yes=1
      ;;
    --purge-user-data)
      purge_user_data=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      die "Unknown option: $1"
      ;;
  esac
  shift
done

command -v pacman >/dev/null 2>&1 || die "pacman was not found. This uninstaller requires CachyOS or another Arch-based distribution."
[[ -r "${PACKAGE_FILE}" ]] || die "Package manifest not found: ${PACKAGE_FILE}"

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

installed_packages=()
for package in "${packages[@]}"; do
  if pacman -Q -- "${package}" >/dev/null 2>&1; then
    installed_packages+=("${package}")
  fi
done

pacman_cmd=(pacman)
if (( EUID != 0 )); then
  command -v sudo >/dev/null 2>&1 || die "sudo is required when the uninstaller is not run as root."
  pacman_cmd=(sudo pacman)
fi

if (( ${#installed_packages[@]} > 0 )); then
  echo "[warn] The following LaTeX packages will be removed:"
  printf '  %s\n' "${installed_packages[@]}"
  echo "[info] Unneeded dependencies will also be removed; pacman will abort if other packages depend on this toolchain."

  if (( ! assume_yes )) && ! confirm "Continue with package removal?"; then
    echo "[done] Package removal cancelled."
    exit 0
  fi

  if ! "${pacman_cmd[@]}" -Rns -- "${installed_packages[@]}"; then
    die "pacman could not remove the complete toolchain. Review the dependency conflicts above; the script will not force cascading removal."
  fi
else
  echo "[ok] None of the manifest packages are installed."
fi

remaining_packages=()
for package in "${packages[@]}"; do
  if pacman -Q -- "${package}" >/dev/null 2>&1; then
    remaining_packages+=("${package}")
  fi
done

if (( ${#remaining_packages[@]} > 0 )); then
  printf '  %s\n' "${remaining_packages[@]}" >&2
  die "Some manifest packages remain installed."
fi

target_home="${HOME:-}"
if (( EUID == 0 )) && [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]] && command -v getent >/dev/null 2>&1; then
  passwd_entry="$(getent passwd "${SUDO_USER}" || true)"
  if [[ -n "${passwd_entry}" ]]; then
    IFS=: read -r _ _ _ _ _ sudo_user_home _ <<< "${passwd_entry}"
    [[ -n "${sudo_user_home}" ]] && target_home="${sudo_user_home}"
  fi
fi

user_tex_paths=()
if [[ -n "${target_home}" && "${target_home}" != "/" ]]; then
  [[ -e "${target_home}/.texlive" ]] && user_tex_paths+=("${target_home}/.texlive")
  [[ -e "${target_home}/texmf" ]] && user_tex_paths+=("${target_home}/texmf")
fi

if (( ${#user_tex_paths[@]} > 0 )); then
  remove_user_data=${purge_user_data}
  echo "[warn] User-managed TeX data was found:"
  printf '  %s\n' "${user_tex_paths[@]}"

  if (( ! purge_user_data && ! assume_yes )); then
    if confirm "Remove these user files too?"; then
      remove_user_data=1
    fi
  elif (( ! purge_user_data )); then
    echo "[info] User TeX data was preserved. Use --purge-user-data to remove it non-interactively."
  fi

  if (( remove_user_data )); then
    rm -rf -- "${user_tex_paths[@]}"
    echo "[ok] User-managed TeX data was removed."
  fi
fi

remaining_tools=()
for tool in latexmk pdflatex bibtex kpsewhich; do
  if command -v "${tool}" >/dev/null 2>&1; then
    remaining_tools+=("${tool}: $(command -v "${tool}")")
  fi
done

if (( ${#remaining_tools[@]} > 0 )); then
  echo "[warn] TeX commands remain available from another installation:"
  printf '  %s\n' "${remaining_tools[@]}"
fi

echo "[done] The pacman-managed LaTeX toolchain from ${PACKAGE_FILE} was removed."
