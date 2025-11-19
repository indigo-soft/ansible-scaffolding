#!/usr/bin/env bash
set -euo pipefail

# Safety/context check: require .git or Makefile present
if [ ! -d .git ] && [ ! -f Makefile ]; then
  echo "❌ Aborting: current directory doesn't look like a git project (no .git and no Makefile)."
  exit 1
fi

# Find files/dirs to delete (exclude safe-list), handle names with spaces/newlines using -print0
mapfile -d '' -t to_delete < <(find . -mindepth 1 -maxdepth 1 \
  ! \( -name '.git' -o -name '.vscode' -o -name '.github' -o -name '.idea' -o -name '.editorconfig' -o -name '.gitattributes' -o -name '.gitignore' -o -name 'LICENSE' -o -name 'Makefile' \) -print0)

if [ ${#to_delete[@]} -eq 0 ]; then
  echo 'Нічого видаляти.'
  exit 0
fi

printf '\033[31m[WARNING]: This will PERMANENTLY DELETE all files and directories\n\t   in the current directory.\033[0m\n'
echo 'Files and directories to be removed:'
for p in "${to_delete[@]}"; do
  # remove leading ./ for readability
  printf '%s\n' "${p#./}"
done

# Non-interactive deletion (as requested for test environment)
printf '%s\0' "${to_delete[@]}" | xargs -0 rm -rf --

echo 'Deletion complete.'
