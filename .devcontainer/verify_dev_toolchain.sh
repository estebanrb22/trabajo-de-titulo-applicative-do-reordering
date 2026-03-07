#!/usr/bin/env bash
# Bash estricto: falla rapido ante errores, variables no definidas y pipes rotos.
set -euo pipefail

# Agrega binarios instalados por ghcup para el usuario actual.
if [[ -d "${HOME}/.ghcup/bin" ]]; then
  export PATH="${HOME}/.ghcup/bin:${PATH}"
fi

# Agrega binarios instalados por cabal para el usuario actual (si no estaban ya en PATH).
if [[ -d "${HOME}/.local/bin" ]] && [[ ":${PATH}:" != *":${HOME}/.local/bin:"* ]]; then
  export PATH="${HOME}/.local/bin:${PATH}"
fi

# Fallback explicito para devcontainers con usuario vscode.
if [[ -d "/home/vscode/.ghcup/bin" ]] && [[ ":${PATH}:" != *":/home/vscode/.ghcup/bin:"* ]]; then
  export PATH="/home/vscode/.ghcup/bin:${PATH}"
fi

# Fallback explicito para binarios de cabal bajo /home/vscode.
if [[ -d "/home/vscode/.local/bin" ]] && [[ ":${PATH}:" != *":/home/vscode/.local/bin:"* ]]; then
  export PATH="/home/vscode/.local/bin:${PATH}"
fi

# Toolchain minima requerida para compilar/testear GHC en este entorno.
required_tools=(ghc cabal alex happy)
readonly MIN_BOOT_GHC_VERSION="9.10"
readonly PINNED_GHC_VERSION="9.14.1"

# Herramientas del sistema requeridas por ./boot en GHC moderno.
required_system_tools=(autoreconf aclocal)
missing_tools=()

# Verifica disponibilidad de cada herramienta en PATH.
for tool in "${required_tools[@]}"; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    missing_tools+=("${tool}")
  fi
done

# Verifica herramientas del sistema para bootstrap/autoreconf.
for tool in "${required_system_tools[@]}"; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    missing_tools+=("${tool}")
  fi
done

# Compara versiones numericas tipo X.Y.Z y retorna exito si actual >= requerida.
version_ge() {
  local actual="$1"
  local required="$2"

  local IFS=.
  local actual_parts=()
  local required_parts=()
  read -r -a actual_parts <<< "${actual}"
  read -r -a required_parts <<< "${required}"

  local max_len=${#actual_parts[@]}
  if (( ${#required_parts[@]} > max_len )); then
    max_len=${#required_parts[@]}
  fi

  local i=0
  while (( i < max_len )); do
    local a="${actual_parts[i]:-0}"
    local b="${required_parts[i]:-0}"

    if (( 10#${a} > 10#${b} )); then
      return 0
    fi
    if (( 10#${a} < 10#${b} )); then
      return 1
    fi

    (( i += 1 ))
  done

  return 0
}

# Si falta algo, falla con mensaje claro para el postCreateCommand.
if (( ${#missing_tools[@]} > 0 )); then
  echo "ERROR: Missing tools in PATH: ${missing_tools[*]}" >&2
  echo "Hint: rebuild the devcontainer to pick up Dockerfile dependencies." >&2
  echo "Hint: for system tools install: sudo apt-get update && sudo apt-get install -y autoconf automake libtool" >&2
  echo "Hint: for Haskell tools reinstall pinned versions via ghcup/cabal." >&2
  exit 1
fi

ghc_version="$(ghc --numeric-version)"
if ! version_ge "${ghc_version}" "${MIN_BOOT_GHC_VERSION}"; then
  echo "ERROR: GHC ${ghc_version} is too old for current vendor/ghc baseline." >&2
  echo "Hint: current configure requires GHC ${MIN_BOOT_GHC_VERSION} or later." >&2
  echo "Hint: run 'ghcup install ghc ${PINNED_GHC_VERSION} && ghcup set ghc ${PINNED_GHC_VERSION}' or rebuild devcontainer." >&2
  exit 1
fi

# Muestra versiones para confirmar setup correcto y reproducible.
echo "[ok] Haskell bootstrap toolchain is available in PATH."
echo "ghc   : ${ghc_version}"
echo "cabal : $(cabal --numeric-version)"
echo "alex  : $(alex --version)"
echo "happy : $(happy --version)"
echo "autoreconf: $(autoreconf --version | sed -n '1p')"
