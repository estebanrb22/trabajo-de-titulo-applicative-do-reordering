#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s <project-dir> <output-dir>\n' "$(basename "$0")" >&2
}

if [ "$#" -ne 2 ]; then
  usage
  exit 1
fi

project_dir="$1"
output_dir="$2"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"

if [[ "$project_dir" = /* ]]; then
  project_dir_abs="$project_dir"
else
  project_dir_abs="$repo_root/$project_dir"
fi

if [[ "$output_dir" = /* ]]; then
  output_dir_abs="$output_dir"
else
  output_dir_abs="$repo_root/$output_dir"
fi

if [ ! -d "$project_dir_abs" ]; then
  printf 'ERROR: project-dir does not exist: %s\n' "$project_dir_abs" >&2
  exit 1
fi

input_file_abs="$project_dir_abs/main.hs"
if [ ! -f "$input_file_abs" ]; then
  printf 'ERROR: expected Cabal main file does not exist: %s\n' "$input_file_abs" >&2
  exit 1
fi

if ! command -v cabal >/dev/null 2>&1; then
  printf 'ERROR: cabal executable was not found in PATH\n' >&2
  exit 1
fi

shopt -s nullglob
cabal_files=("$project_dir_abs"/*.cabal)
shopt -u nullglob

if [ "${#cabal_files[@]}" -eq 0 ]; then
  printf 'ERROR: no .cabal file found in project-dir: %s\n' "$project_dir_abs" >&2
  exit 1
fi

if [ "${#cabal_files[@]}" -ne 1 ]; then
  printf 'ERROR: expected exactly one .cabal file in project-dir, found %d\n' "${#cabal_files[@]}" >&2
  exit 1
fi

cabal_file_abs="${cabal_files[0]}"
executable_name="$(awk 'tolower($1) == "executable" { print $2; exit }' "$cabal_file_abs")"

if [ -z "$executable_name" ]; then
  printf 'ERROR: could not find an executable stanza in %s\n' "$cabal_file_abs" >&2
  exit 1
fi

cabal_target="exe:$executable_name"
cabal_build_root="$output_dir_abs/cabal-build"
rewrite_do_variant_script="$script_dir/rewrite-do-variant.sh"

if [ ! -x "$rewrite_do_variant_script" ]; then
  printf 'ERROR: expected preprocessor executable does not exist: %s\n' "$rewrite_do_variant_script" >&2
  exit 1
fi

source "$script_dir/common.sh"

semantic_validation_prepare_backend() {
  if [ -z "$output_dir_abs" ] || [ "$output_dir_abs" = "/" ]; then
    printf 'ERROR: refusing to clean cabal-build under unsafe output-dir: %s\n' "$output_dir_abs" >&2
    exit 1
  fi

  rm -rf "$cabal_build_root"
  mkdir -p "$cabal_build_root"
}

semantic_validation_log_context() {
  log_summary "== Semantic validation reorder (Cabal) =="
  log_summary "project-dir = $project_dir_abs"
  log_summary "input-file = $input_file_abs"
  log_summary "cabal-file = $cabal_file_abs"
  log_summary "target = $cabal_target"
  log_summary "output-dir = $output_dir_abs"
  log_summary "cabal-build-root = $cabal_build_root"
  log_summary ""
}

copy_cabal_candidate_binary() {
  local name="$1"
  local ghc_output_tmp="$2"
  local bin_path="$bin_dir/$name"
  local candidate_build_dir="$cabal_build_root/$name"
  local list_bin_output
  local bin_source

  if ! list_bin_output="$(cd "$project_dir_abs" && cabal list-bin "--builddir=$candidate_build_dir" "$cabal_target" 2>> "$ghc_output_tmp")"; then
    cat "$ghc_output_tmp" >&2
    log_summary "ERROR: cabal list-bin failed for $name"
    return 1
  fi

  bin_source="$(printf '%s\n' "$list_bin_output" | awk 'NF { last = $0 } END { print last }')"
  if [ -z "$bin_source" ]; then
    cat "$ghc_output_tmp" >&2
    log_summary "ERROR: cabal list-bin did not return a binary path for $name"
    return 1
  fi

  if [[ "$bin_source" != /* ]]; then
    bin_source="$project_dir_abs/$bin_source"
  fi

  if [ ! -x "$bin_source" ]; then
    cat "$ghc_output_tmp" >&2
    log_summary "ERROR: cabal binary is not executable for $name: $bin_source"
    return 1
  fi

  cp "$bin_source" "$bin_path"
  chmod +x "$bin_path"
}

compile_original() {
  local name="original"
  local bin_path="$bin_dir/$name"
  local candidate_build_dir="$cabal_build_root/$name"
  local ghc_output_tmp
  local ghc_options="-fforce-recomp -XNoApplicativeDo -XNoQualifiedDo -F -pgmF $rewrite_do_variant_script"
  local -a cmd

  cmd=(cabal build "--builddir=$candidate_build_dir" "$cabal_target" "--ghc-options=$ghc_options")

  log_summary "[COMPILE] $name -> $bin_path"
  ghc_output_tmp="$(mktemp)"
  mkdir -p "$candidate_build_dir"

  if (cd "$project_dir_abs" && SEMANTIC_VALIDATION_DO_VARIANT=original "${cmd[@]}") > "$ghc_output_tmp" 2>&1; then
    if ! copy_cabal_candidate_binary "$name" "$ghc_output_tmp"; then
      rm -f "$ghc_output_tmp"
      exit 1
    fi

    rm -f "$ghc_output_tmp"
  else
    cat "$ghc_output_tmp" >&2
    rm -f "$ghc_output_tmp"
    log_summary "ERROR: compilation failed for $name"
    exit 1
  fi
}

compile_original_ado() {
  local name="original_ado"
  local bin_path="$bin_dir/$name"
  local candidate_build_dir="$cabal_build_root/$name"
  local ghc_output_tmp
  local ghc_options="-fforce-recomp -XApplicativeDo -XNoQualifiedDo -ddump-rn-trace -F -pgmF $rewrite_do_variant_script"
  local -a cmd

  cmd=(cabal build "--builddir=$candidate_build_dir" "$cabal_target" "--ghc-options=$ghc_options")

  log_summary "[COMPILE] $name -> $bin_path"
  ghc_output_tmp="$(mktemp)"
  mkdir -p "$candidate_build_dir"

  if (cd "$project_dir_abs" && SEMANTIC_VALIDATION_DO_VARIANT=original_ado "${cmd[@]}") > "$ghc_output_tmp" 2>&1; then
    if ! write_original_ado_log_from_compile_output "$ghc_output_tmp"; then
      cat "$ghc_output_tmp" >&2
      rm -f "$ghc_output_tmp"
      log_summary "ERROR: could not process renamer trace for $name"
      exit 1
    fi

    if ! copy_cabal_candidate_binary "$name" "$ghc_output_tmp"; then
      rm -f "$ghc_output_tmp"
      exit 1
    fi

    rm -f "$ghc_output_tmp"
  else
    cat "$ghc_output_tmp" >&2
    rm -f "$ghc_output_tmp"
    log_summary "ERROR: compilation failed for $name"
    exit 1
  fi
}

compile_candidate() {
  local name="$1"
  local candidate_n="${2:-}"
  local bin_path="$bin_dir/$name"
  local candidate_build_dir="$cabal_build_root/$name"
  local ghc_output_tmp
  local ghc_options="-fforce-recomp -ddump-rn-trace"
  local -a cmd

  if [ -n "$candidate_n" ]; then
    ghc_options="$ghc_options -fado-reorder-candidate-n=$candidate_n"
  fi

  cmd=(cabal build "--builddir=$candidate_build_dir" "$cabal_target" "--ghc-options=$ghc_options")

  log_summary "[COMPILE] $name -> $bin_path"
  ghc_output_tmp="$(mktemp)"
  mkdir -p "$candidate_build_dir"

  if (cd "$project_dir_abs" && "${cmd[@]}") > "$ghc_output_tmp" 2>&1; then
    if ! semantic_validation_process_compile_success "$name" "$candidate_n" "$ghc_output_tmp"; then
      cat "$ghc_output_tmp" >&2
      rm -f "$ghc_output_tmp"
      log_summary "ERROR: could not process renamer trace for $name"
      exit 1
    fi

    if ! copy_cabal_candidate_binary "$name" "$ghc_output_tmp"; then
      rm -f "$ghc_output_tmp"
      exit 1
    fi

    rm -f "$ghc_output_tmp"
  else
    semantic_validation_process_compile_failure "$name" "$candidate_n" "$ghc_output_tmp"
    rm -f "$ghc_output_tmp"
    exit 1
  fi
}

run_semantic_validation_reorder
