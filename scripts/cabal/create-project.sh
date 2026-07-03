#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s <project-dir>\n' "$(basename "$0")" >&2
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

derive_package_name() {
  local package_path="$1"
  local path_part
  local name_part
  local pkg=""
  local IFS
  local -a path_parts
  local -a name_parts

  IFS='/' read -ra path_parts <<< "$package_path"
  for path_part in "${path_parts[@]}"; do
    if [ -z "$path_part" ]; then
      continue
    fi

    if [[ "$path_part" =~ ^([0-9]+)-defs$ ]]; then
      name_parts=("${BASH_REMATCH[1]}defs")
    else
      IFS='-' read -ra name_parts <<< "$path_part"
    fi

    for name_part in "${name_parts[@]}"; do
      if [ -z "$name_part" ]; then
        die "project-dir contains an empty package-name component: $package_path"
      fi

      if [[ "$name_part" =~ ^[0-9]+$ ]]; then
        name_part="n$name_part"
      fi

      if [ -z "$pkg" ]; then
        pkg="$name_part"
      else
        pkg="$pkg-$name_part"
      fi
    done
  done

  printf '%s\n' "$pkg"
}

validate_package_name() {
  local pkg="$1"
  local pkg_part
  local IFS
  local -a pkg_parts

  if [[ ! "$pkg" =~ ^[A-Za-z0-9]+(-[A-Za-z0-9]+)*$ ]]; then
    die "derived package name is not valid for Cabal: $pkg"
  fi

  IFS='-' read -ra pkg_parts <<< "$pkg"
  for pkg_part in "${pkg_parts[@]}"; do
    if [[ ! "$pkg_part" =~ [A-Za-z] ]]; then
      die "derived package name component must contain a letter: $pkg_part"
    fi
  done
}

if [ "$#" -ne 1 ]; then
  usage
  exit 1
fi

project_arg="${1%/}"
project_arg="${project_arg#./}"
if [ -z "$project_arg" ]; then
  usage
  exit 1
fi

if ! command -v cabal >/dev/null 2>&1; then
  die "cabal executable was not found in PATH"
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"

if [[ "$project_arg" = /* ]]; then
  case "$project_arg" in
    "$repo_root"/experiments/*)
      project_dir="$project_arg"
      package_path="${project_arg#"$repo_root/experiments/"}"
      ;;
    *)
      die "project-dir must be inside $repo_root/experiments"
      ;;
  esac
elif [[ "$project_arg" == experiments/* ]]; then
  project_dir="$repo_root/$project_arg"
  package_path="${project_arg#experiments/}"
else
  project_dir="$repo_root/experiments/$project_arg"
  package_path="$project_arg"
fi

if [ -z "$package_path" ] || [ "$package_path" = "experiments" ]; then
  die "project-dir must include a path below experiments/"
fi

pkg="$(derive_package_name "$package_path")"
validate_package_name "$pkg"

mkdir -p "$project_dir"

cd "$project_dir"
cabal init -n --exe --package-name "$pkg" --language GHC2024 \
  --minimal --no-comments --license NONE --main-is main.hs --application-dir .

rm -f CHANGELOG.md
printf 'import: /workspaces/tt-repo/config/cabal.project\npackages: .\n' > cabal.project

cat > main.hs <<'HS'
{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE QualifiedDo #-}

module Main (main) where

import qualified Control.Monad.CommutativeDo as CD

instance CD.CommutativeMonad Maybe

defaultExample :: Maybe Int
defaultExample = CD.do
  x1 <- Just 5
  x2 <- Just 10
  x3 <- Just (x1 + 15)
  x4 <- Just (x2 + 20)
  CD.return (x3 + x4)

main :: IO ()
main = print defaultExample
HS

printf '[ok] Created Cabal project: %s\n' "$project_dir"
printf '[ok] Cabal package name: %s\n' "$pkg"
