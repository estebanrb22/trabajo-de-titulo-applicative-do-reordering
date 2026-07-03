#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s <input-file> <output-dir>\n' "$(basename "$0")" >&2
}

if [ "$#" -ne 2 ]; then
  usage
  exit 1
fi

input_file="$1"
output_dir="$2"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"

if [[ "$input_file" = /* ]]; then
  input_file_abs="$input_file"
else
  input_file_abs="$repo_root/$input_file"
fi

if [[ "$output_dir" = /* ]]; then
  output_dir_abs="$output_dir"
else
  output_dir_abs="$repo_root/$output_dir"
fi

if [ ! -f "$input_file_abs" ]; then
  printf 'ERROR: input-file does not exist: %s\n' "$input_file_abs" >&2
  exit 1
fi

ghc_bin="$repo_root/vendor/ghc/_build/stage1/bin/ghc"
if [ ! -x "$ghc_bin" ]; then
  printf 'ERROR: expected GHC executable does not exist: %s\n' "$ghc_bin" >&2
  exit 1
fi

input_dir="$(dirname -- "$input_file_abs")"
rewrite_do_variant_script="$script_dir/rewrite-do-variant.sh"

if [ ! -x "$rewrite_do_variant_script" ]; then
  printf 'ERROR: expected preprocessor executable does not exist: %s\n' "$rewrite_do_variant_script" >&2
  exit 1
fi

source "$script_dir/common.sh"

semantic_validation_log_context() {
  log_summary "== Semantic validation reorder (GHC) =="
  log_summary "input-file = $input_file_abs"
  log_summary "output-dir = $output_dir_abs"
  log_summary ""
}

compile_original() {
  local name="original"
  local bin_path="$bin_dir/$name"
  local ghc_output_tmp
  local cmd=("$ghc_bin" -fforce-recomp -XNoApplicativeDo -XNoQualifiedDo "-i$input_dir" -F -pgmF "$rewrite_do_variant_script" "$input_file_abs" -o "$bin_path")

  log_summary "[COMPILE] $name -> $bin_path"
  ghc_output_tmp="$(mktemp)"

  if SEMANTIC_VALIDATION_DO_VARIANT=original "${cmd[@]}" > "$ghc_output_tmp" 2>&1; then
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
  local ghc_output_tmp
  local cmd=("$ghc_bin" -fforce-recomp -XApplicativeDo -XNoQualifiedDo -ddump-rn-trace "-i$input_dir" -F -pgmF "$rewrite_do_variant_script" "$input_file_abs" -o "$bin_path")

  log_summary "[COMPILE] $name -> $bin_path"
  ghc_output_tmp="$(mktemp)"

  if SEMANTIC_VALIDATION_DO_VARIANT=original_ado "${cmd[@]}" > "$ghc_output_tmp" 2>&1; then
    if ! write_original_ado_log_from_compile_output "$ghc_output_tmp"; then
      cat "$ghc_output_tmp" >&2
      rm -f "$ghc_output_tmp"
      log_summary "ERROR: could not process renamer trace for $name"
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
  local ghc_output_tmp
  local cmd=("$ghc_bin" -fforce-recomp -ddump-rn-trace "-i$input_dir")

  if [ -n "$candidate_n" ]; then
    cmd+=("-fado-reorder-candidate-n=$candidate_n")
  fi

  cmd+=("$input_file_abs" -o "$bin_path")

  log_summary "[COMPILE] $name -> $bin_path"
  ghc_output_tmp="$(mktemp)"

  if "${cmd[@]}" > "$ghc_output_tmp" 2>&1; then
    if ! semantic_validation_process_compile_success "$name" "$candidate_n" "$ghc_output_tmp"; then
      cat "$ghc_output_tmp" >&2
      rm -f "$ghc_output_tmp"
      log_summary "ERROR: could not process renamer trace for $name"
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
