#!/usr/bin/env bash
set -euo pipefail

root_dir="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${root_dir}" ]]; then
  echo "ERROR: Run this script inside the repository." >&2
  exit 1
fi

readonly example_dir="${root_dir}/experiments/applicative-do"

normalize_ghc_bin() {
  local ghc_path="$1"

  if [[ "${ghc_path}" = /* ]]; then
    echo "${ghc_path}"
    return 0
  fi

  if [[ "${ghc_path}" == */* ]]; then
    echo "${root_dir}/${ghc_path#./}"
    return 0
  fi

  echo "${ghc_path}"
}

pick_ghc() {
  if [[ -n "${GHC_BIN:-}" ]]; then
    normalize_ghc_bin "${GHC_BIN}"
    return 0
  fi

  local candidates=(
    "${root_dir}/vendor/ghc/_build/stage1/bin/ghc"
    "${root_dir}/vendor/ghc/_build/stage2/bin/ghc"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -x "${candidate}" ]]; then
      echo "${candidate}"
      return 0
    fi
  done

  if command -v ghc >/dev/null 2>&1; then
    command -v ghc
    return 0
  fi

  return 1
}

ghc_bin="$(pick_ghc || true)"
if [[ -z "${ghc_bin}" ]]; then
  cat >&2 <<'EOF'
ERROR: Could not find a GHC binary.

Options:
1) Build GHC inside vendor/ghc:
   cd vendor/ghc && ./boot && ./configure && ./hadrian/build -j"$(nproc)" --flavour=devel2 && cd ../..

2) Re-run this script forcing a binary from the submodule, for example:
   GHC_BIN=vendor/ghc/_build/stage1/bin/ghc bash experiments/applicative-do/run.sh

3) Install ghc in PATH and re-run this script.
EOF
  exit 1
fi

if [[ "${ghc_bin}" == */* ]] && [[ ! -x "${ghc_bin}" ]]; then
  echo "ERROR: GHC binary not found or not executable: ${ghc_bin}" >&2
  echo "Tip: if GHC_BIN is relative, it is resolved from repo root: ${root_dir}" >&2
  exit 1
fi

echo "[info] Using GHC: ${ghc_bin}"

mkdir -p "${example_dir}/build"

dump_flags=()
generated_dumps=()

if [[ "${DUMP_PIPELINE:-0}" == "1" ]]; then
  dump_flags+=( -ddump-rn -ddump-tc -ddump-ds -ddump-to-file )
  generated_dumps+=( src/Main.dump-rn src/Main.dump-tc src/Main.dump-ds )
fi

if [[ "${DUMP_DS:-0}" == "1" ]] && [[ "${DUMP_PIPELINE:-0}" != "1" ]]; then
  dump_flags+=( -ddump-ds -ddump-to-file -dsuppress-all -dsuppress-uniques )
  generated_dumps+=( src/Main.dump-ds )
fi

if [[ "${DUMP_SIMPL:-0}" == "1" ]]; then
  dump_flags+=( -ddump-simpl -ddump-to-file )
  generated_dumps+=( src/Main.dump-simpl )
fi

if [[ -n "${EXTRA_GHC_FLAGS:-}" ]]; then
  # shellcheck disable=SC2206
  extra_ghc_flags=( ${EXTRA_GHC_FLAGS} )
else
  extra_ghc_flags=()
fi

(
  cd "${example_dir}"
  "${ghc_bin}" "${dump_flags[@]}" "${extra_ghc_flags[@]}" -O0 -Wall -fforce-recomp src/Main.hs -o build/applicative-do-demo
  ./build/applicative-do-demo
)

if [[ "${#generated_dumps[@]}" -gt 0 ]]; then
  manifest_path="${example_dir}/build/dump-manifest.txt"
  {
    echo "Generated dump files:"
    for dump_file in "${generated_dumps[@]}"; do
      echo "- experiments/applicative-do/${dump_file}"
    done
  } > "${manifest_path}"

  echo "[info] Dump manifest generated at experiments/applicative-do/build/dump-manifest.txt"
  for dump_file in "${generated_dumps[@]}"; do
    echo "[info] Dump available at experiments/applicative-do/${dump_file}"
  done
else
  rm -f "${example_dir}/build/dump-manifest.txt"
fi
