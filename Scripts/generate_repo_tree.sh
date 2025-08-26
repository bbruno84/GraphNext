#!/usr/bin/env bash
# generate_repo_tree.sh — generate Docs/repo_tree.md with branch-agnostic relative links
# Bash (portable), BSD find compatible, no eval, no command substitution in predicates

set -euo pipefail

OUT="Docs/repo_tree.md"
ROOT="."

# Excluded dir NAMES (filtered at each level)
EXCL_DIR1='.git'
EXCL_DIR2='.build'
EXCL_DIR3='.swiftpm'
EXCL_DIR4='DerivedData'
EXCL_DIR5='.github'
# Excluded file path (from repo root)
EXCLUDE_FILE='./Docs/repo_tree.md'

mkdir -p "$(dirname "$OUT")"

rel_link() {
  p=$1
  case "$p" in
    ./*) p=${p#./} ;;
  esac
  printf '../%s' "$p"
}

slug() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
}

# List immediate child directories (exclude by name at this level)
list_dirs() {
  local base="$1"
  find "$base" -mindepth 1 -maxdepth 1 -type d \
    ! -name '.*' \
    ! -name "$EXCL_DIR1" ! -name "$EXCL_DIR2" ! -name "$EXCL_DIR3" ! -name "$EXCL_DIR4" ! -name "$EXCL_DIR5" \
    -print | LC_ALL=C sort
}

# List immediate child files (dirs are not returned, so excludes not needed here)
list_files() {
  local base="$1"
  find "$base" -mindepth 1 -maxdepth 1 \
    ! -name '.*' \
    ! -name '.DS_Store' ! -name '.gitignore' \
    -type f -print | LC_ALL=C sort
}

is_excluded_file() {
  local p="$1"
  [ "$p" = "$EXCLUDE_FILE" ] && return 0 || return 1
}

# IFS to real newline for safe loops
OLDIFS=$IFS
IFS='
'

TOP_LEVEL_DIRS=$(list_dirs "$ROOT")
TOP_LEVEL_FILES=$(list_files "$ROOT")

{
  printf '# Repository Tree\n\n'
  printf '_Link relativi (branch-agnostici). Aggiornato automaticamente dalla CI._\n\n'
  printf '## Table of Contents\n\n'
  for f in $TOP_LEVEL_FILES; do
    is_excluded_file "$f" && continue
    name=${f#./}
    printf -- '- [%s](#%s)\n' "$name" "$(slug "$name")"
  done
  for d in $TOP_LEVEL_DIRS; do
    name=${d#./}
    printf -- '- [%s/](#%s)\n' "$name" "$(slug "$name")"
  done
  printf '\n'
} > "$OUT"

print_tree() {
  local base="$1"
  local indent="$2"
  local prefix="$3"
  local files
  local dirs
  local count
  local idx

  files=$(list_files "$base")
  dirs=$(list_dirs "$base")

  for f in $files; do
    is_excluded_file "$f" && continue
    name=${f#./}
    printf '%s%s[%s](%s)\n' "$indent" "$prefix" "$name" "$(rel_link "$f")" >> "$OUT"
  done

  count=0
  for _d in $dirs; do count=$((count+1)); done
  idx=0
  for d in $dirs; do
    idx=$((idx+1))
    name=${d#./}
    if [ "$idx" -eq "$count" ]; then
      branch='└── '
      next_indent="${indent}    "
    else
      branch='├── '
      next_indent="${indent}│   "
    fi
    printf '%s%s**%s/**\n' "$indent" "$branch" "$name" >> "$OUT"
    print_tree "$d" "$next_indent" '├── '
  done
}

# Sections for files
for f in $TOP_LEVEL_FILES; do
  is_excluded_file "$f" && continue
  name=${f#./}
  printf '## %s\n' "$name" >> "$OUT"
  printf -- '- [%s](%s)\n\n' "$name" "$(rel_link "$f")" >> "$OUT"
done

# Sections for directories
for d in $TOP_LEVEL_DIRS; do
  name=${d#./}
  printf '## %s/\n' "$name" >> "$OUT"
  printf -- '- **[%s/](%s)**\n' "$name" "$(rel_link "$d")" >> "$OUT"
  print_tree "$d" '' '├── '
  printf '\n' >> "$OUT"
done

# Restore IFS
IFS=$OLDIFS
