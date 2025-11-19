#!/usr/bin/env bash
set -euo pipefail

# Safety/context check
if [ ! -d .git ] && [ ! -f Makefile ]; then
  echo "❌ Aborting: current directory doesn't look like a git project (no .git and no Makefile)."
  exit 1
fi

mapfile -d '' -t to_delete < <(find . -mindepth 1 -maxdepth 1 \
  ! \( -name '.git' -o -name '.vscode' -o -name '.github' -o -name '.idea' -o -name '.editorconfig' -o -name '.gitattributes' -o -name '.gitignore' -o -name 'LICENSE' -o -name 'Makefile' \) -print0)

if [ ${#to_delete[@]} -eq 0 ]; then
  echo 'Нічого видаляти.'
  exit 0
fi

echo 'Files and directories that would be removed:'
for p in "${to_delete[@]}"; do
  printf '%s\n' "${p#./}"
done
