#
//  generate_repo_tree.sh
//  GraphNext
//
//  Created by Valerio Buriani on 25/08/25.
//


#!/bin/bash
set -euo pipefail

# Config
OUT="Docs/repo_tree.md"
ROOT="."
EXCLUDES=(
  "*/.git/*"
  "*/.build/*"
  "*/.swiftpm/*"
  "*/DerivedData/*"
  "*/Docs/repo_tree.md"
)

# Ensure output dir
mkdir -p "$(dirname "$OUT")"

# Helpers
rel_link() {           # produce link relativo da Docs/ al path passato
  local p="$1"
  echo "../${p#./}"
}

slug() {               # slugify per anchor markdown
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
}

# Raccolta directory top-level e file
readarray -t TOP_LEVEL < <(find "$ROOT" -maxdepth 1 -mindepth 1 -type d | sort)
readarray -t TOP_FILES  < <(find "$ROOT" -maxdepth 1 -mindepth 1 -type f | sort)

# Header + TOC
{
  echo "# Repository Tree"
  echo
  echo "_Link relativi (branch‑agnostici). Aggiornato automaticamente dalla CI._"
  echo
  echo "## Table of Contents"
  echo
  for f in "${TOP_FILES[@]}"; do
    name="${f#./}"
    echo "- [${name}](#$(slug "$name"))"
  done
  for d in "${TOP_LEVEL[@]}"; do
    name="${d#./}"
    echo "- [${name}/](#$(slug "$name"))"
  done
  echo
} > "$OUT"

# Funzione per stampare un blocco tree ricorsivo
print_tree() {
  local base="$1"       # directory da stampare
  local indent="$2"     # prefisso indentazione
  local prefix="$3"     # prefisso grafico (es. "├── ")

  # Filtra con excludes
  local find_cmd=(find "$base" -mindepth 1 -maxdepth 1)
  for pat in "${EXCLUDES[@]}"; do
    find_cmd+=( -not -path "$pat" )
  done

  # File in questa cartella
  readarray -t files < <("${find_cmd[@]}" -type f | sort)
  # Directory in questa cartella
  readarray -t dirs  < <("${find_cmd[@]}" -type d | sort)

  # Stampa file
  for f in "${files[@]}"; do
    local name="${f#./}"
    echo "${indent}${prefix}[${name}]($(rel_link "$f"))" >> "$OUT"
  done

  # Stampa directory e ricorri
  local count="${#dirs[@]}"
  local idx=0
  for d in "${dirs[@]}"; do
    ((idx++))
    local name="${d#./}"
    local is_last=$([ "$idx" -eq "$count" ] && echo 1 || echo 0)
    local branch="├── "
    local next_indent="${indent}│   "
    if [ "$is_last" -eq 1 ]; then
      branch="└── "
      next_indent="${indent}    "
    fi
    echo "${indent}${branch}**${name}/**" >> "$OUT"
    print_tree "$d" "$next_indent" "├── "
  done
}

# Sezione per ciascun file top-level
for f in "${TOP_FILES[@]}"; do
  name="${f#./}"
  echo "## ${name}" >> "$OUT"
  echo "- [${name}]($(rel_link "$f"))" >> "$OUT"
  echo >> "$OUT"
done

# Sezione per ciascuna directory top-level
for d in "${TOP_LEVEL[@]}"; do
  name="${d#./}"
  echo "## ${name}/" >> "$OUT"
  echo "- **[${name}/]($(rel_link "$d"))**" >> "$OUT"
  print_tree "$d" "" "├── "
  echo >> "$OUT"
done