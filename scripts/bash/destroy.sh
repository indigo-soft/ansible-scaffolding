#!/usr/bin/env bash
set -euo pipefail

# check_context: ensure script is run in a project root
check_context() {
  if [ ! -d .git ] && [ ! -f Makefile ]; then
    echo "❌ Aborting: current directory doesn't look like a git project (no .git and no Makefile)."
    exit 1
  fi
}

# find_targets: collect files/dirs to delete, excluding safe-list
find_targets() {
  mapfile -d '' -t to_delete < <(find . -mindepth 1 -maxdepth 1 \
    ! \( -name '.git' -o -name '.vscode' -o -name 'scripts' -o -name 'README.md' -o -name '.github' -o -name '.idea' -o -name '.editorconfig' -o -name '.gitattributes' -o -name '.gitignore' -o -name 'LICENSE' -o -name 'Makefile' \) -print0)
}

# print_warning: show what will be deleted
print_warning() {
  printf '\033[31m[WARNING]: This will PERMANENTLY DELETE all files and directories\n\t   in the current directory.\033[0m\n'
  echo 'Files and directories to be removed:'
  for p in "${to_delete[@]}"; do
    printf '%s\n' "${p#./}"
  done
}

# confirm_deletion: prompt user for yes/no before proceeding
confirm_deletion() {
  local answer
  while true; do
    read -rp "Are you sure you want to delete these files? (yes/no): " answer
    case "$answer" in
      y|Y|yes|Yes|YES)
        return 0
        ;;
      n|N|no|No|NO)
        echo "Deletion cancelled."
        exit 0
        ;;
      *)
        echo "Please enter 'yes' or 'no'."
        ;;
    esac
  done
}

# do_delete: perform the actual deletion
do_delete() {
  printf '%s\0' "${to_delete[@]}" | xargs -0 rm -rf --
  echo 'Deletion complete.'
}

# main: orchestrate destroy logic
main() {
  check_context
  find_targets
  if [ ${#to_delete[@]} -eq 0 ]; then
    echo 'Nothing to delete.'
    exit 0
  fi
  print_warning
  confirm_deletion
  do_delete
}

main "$@"
