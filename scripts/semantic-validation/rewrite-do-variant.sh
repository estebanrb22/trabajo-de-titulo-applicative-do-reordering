#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  printf 'Usage: %s <input-file> <output-file>\n' "$(basename "$0")" >&2
  exit 1
fi

variant="${SEMANTIC_VALIDATION_DO_VARIANT:-original}"
case "$variant" in
  original|original_ado) ;;
  *)
    printf 'ERROR: unsupported SEMANTIC_VALIDATION_DO_VARIANT: %s\n' "$variant" >&2
    exit 1
    ;;
esac

args=("$@")
input_file="${args[$#-2]}"
output_file="${args[$#-1]}"

awk -v variant="$variant" '
  function trim(s) {
    sub(/^[[:space:]]+/, "", s)
    sub(/[[:space:]]+$/, "", s)
    return s
  }

  function should_drop_extension(ext) {
    if (ext == "QualifiedDo") return 1
    if (variant == "original" && ext == "ApplicativeDo") return 1
    return 0
  }

  function maybe_print_original_ado_pragma() {
    if (variant == "original_ado" && !saw_applicative_do && !inserted_applicative_do) {
      print "{-# LANGUAGE ApplicativeDo #-}"
      inserted_applicative_do = 1
    }
  }

  /^[[:space:]]*{-#([[:space:]]*)LANGUAGE[[:space:]]+/ && /#-}/ {
    line = $0
    sub(/^[[:space:]]*{-#([[:space:]]*)LANGUAGE[[:space:]]*/, "", line)
    sub(/[[:space:]]*#-}.*/, "", line)

    out = ""
    n = split(line, exts, ",")
    for (i = 1; i <= n; i++) {
      ext = trim(exts[i])
      if (ext == "") continue
      if (ext == "ApplicativeDo") saw_applicative_do = 1
      if (should_drop_extension(ext)) continue

      if (out != "") out = out ", "
      out = out ext
    }

    if (out != "") print "{-# LANGUAGE " out " #-}"
    next
  }

  /^[[:space:]]*import[[:space:]]+qualified[[:space:]]+Control[.]Monad[.]CommutativeDo[[:space:]]+as[[:space:]]+CD([[:space:]]*$|[[:space:]]+--)/ {
    next
  }

  /^[[:space:]]*instance[[:space:]]+CD[.]CommutativeMonad([[:space:]]|$)/ {
    next
  }

  {
    maybe_print_original_ado_pragma()
    line = $0
    gsub(/CD[.]do/, "do", line)
    gsub(/CD[.]return/, "return", line)
    print line
  }
' "$input_file" > "$output_file"
