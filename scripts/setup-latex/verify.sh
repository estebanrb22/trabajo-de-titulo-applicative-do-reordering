#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGE_FILE="${SCRIPT_DIR}/cachyos-packages.txt"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

if (( $# > 0 )); then
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: bash scripts/setup-latex/verify.sh"
    exit 0
  fi
  die "This script does not accept arguments."
fi

command -v pacman >/dev/null 2>&1 || die "pacman was not found. This verifier requires CachyOS or another Arch-based distribution."
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

missing_packages=()
for package in "${packages[@]}"; do
  if ! pacman -Q -- "${package}" >/dev/null 2>&1; then
    missing_packages+=("${package}")
  fi
done

if (( ${#missing_packages[@]} > 0 )); then
  echo "ERROR: Missing pacman packages:" >&2
  printf '  %s\n' "${missing_packages[@]}" >&2
  exit 1
fi

required_tools=(latexmk pdflatex bibtex kpsewhich)
missing_tools=()
for tool in "${required_tools[@]}"; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    missing_tools+=("${tool}")
  fi
done

if (( ${#missing_tools[@]} > 0 )); then
  echo "ERROR: Missing LaTeX commands:" >&2
  printf '  %s\n' "${missing_tools[@]}" >&2
  exit 1
fi

required_tex_files=(
  book.cls
  inputenc.sty
  geometry.sty
  amsmath.sty
  amssymb.sty
  amsthm.sty
  graphicx.sty
  caption.sty
  appendix.sty
  babel.sty
  spanish.ldf
  babel-es.ini
  hyperref.sty
  listings.sty
  pgffor.sty
  etoolbox.sty
  lipsum.sty
  xcolor.sty
  array.sty
  booktabs.sty
  placeins.sty
  tabularx.sty
  tikz.sty
  tikzlibrarypositioning.code.tex
  tikzlibraryshapes.geometric.code.tex
  plain.bst
  cm-super-ts1.enc
  tcrm1200.tfm
  sfrm1200.pfb
)

missing_tex_files=()
for tex_file in "${required_tex_files[@]}"; do
  if [[ -z "$(kpsewhich "${tex_file}")" ]]; then
    missing_tex_files+=("${tex_file}")
  fi
done

if (( ${#missing_tex_files[@]} > 0 )); then
  echo "ERROR: Missing TeX files:" >&2
  printf '  %s\n' "${missing_tex_files[@]}" >&2
  exit 1
fi

temp_dir="$(mktemp -d)"
cleanup() {
  rm -rf -- "${temp_dir}"
}
trap cleanup EXIT

read -r -d '' smoke_tex <<'EOF' || true
\documentclass{book}
\usepackage[utf8]{inputenc}
\usepackage[top=2cm,left=3cm,bottom=2cm,right=2cm,paper=letterpaper]{geometry}
\usepackage{amsmath,amssymb,amsthm,graphicx}
\usepackage{caption}
\usepackage[titletoc]{appendix}
\usepackage[spanish,es-nolists,es-lcroman]{babel}
\usepackage[pdfpagelabels,hidelinks]{hyperref}
\usepackage{listings}
\usepackage{pgffor}
\usepackage{lipsum}
\usepackage[table]{xcolor}
\usepackage{array}
\usepackage{booktabs}
\usepackage{etoolbox}
\usepackage{placeins}
\usepackage{tabularx}
\usepackage{tikz}
\usetikzlibrary{positioning,shapes.geometric}

\newbool{smoketest}
\booltrue{smoketest}

\begin{document}
\chapter{Verification}

\begin{equation}
  1 + 1 = 2
\end{equation}

\begin{lstlisting}[language=Haskell]
main = pure ()
\end{lstlisting}

\begin{tabularx}{\textwidth}{>{\centering\arraybackslash}X}
\toprule
LaTeX smoke test \\
\bottomrule
\end{tabularx}

\begin{tikzpicture}
  \node[draw,rectangle] (source) {Source};
  \node[draw,diamond,right=of source] {Result};
\end{tikzpicture}

\foreach \value in {1,2}{\value\ }
\FloatBarrier
Reference check~\cite{smoke}.

\begin{appendices}
\chapter{Smoke appendix}
Package loading succeeded.
\end{appendices}

\bibliographystyle{plain}
\bibliography{references}
\end{document}
EOF

read -r -d '' smoke_bib <<'EOF' || true
@book{smoke,
  author = {TeX Live},
  title = {Installation Verification},
  publisher = {TeX Live},
  year = {2026}
}
EOF

printf '%s\n' "${smoke_tex}" > "${temp_dir}/smoke.tex"
printf '%s\n' "${smoke_bib}" > "${temp_dir}/references.bib"

echo "[run] Compiling a temporary LaTeX and BibTeX smoke test."
if ! (
  cd "${temp_dir}"
  latexmk -pdf -bibtex -interaction=nonstopmode -halt-on-error -file-line-error smoke.tex > latexmk-output.log 2>&1
); then
  while IFS= read -r output_line; do
    printf '%s\n' "${output_line}" >&2
  done < "${temp_dir}/latexmk-output.log"
  die "The temporary LaTeX compilation failed."
fi

[[ -s "${temp_dir}/smoke.pdf" ]] || die "The smoke test did not produce a PDF."
[[ -s "${temp_dir}/smoke.bbl" ]] || die "The smoke test did not produce BibTeX output."

if grep -Eq "There were undefined references|Citation .* undefined" "${temp_dir}/smoke.log"; then
  die "The smoke test finished with unresolved citations or references."
fi

echo "[ok] All required pacman packages, TeX files, commands, fonts, and BibTeX support are available."
echo "[done] The LaTeX toolchain can compile the package set used by reports/informe."
