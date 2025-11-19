#!/usr/bin/env bash
set -euo pipefail

# check_context: ensure script is run in a project root
check_context() {
    if [ ! -d .git ] && [ ! -f Makefile ]; then
        echo "❌ Aborting: current directory doesn't look like a git project (no .git and no Makefile)."
        exit 1
    fi
}

# find_targets: collect files/dirs to preview for deletion, excluding safe-list
find_targets() {
    mapfile -d '' -t to_delete < <(find . -mindepth 1 -maxdepth 1 \
        ! \( -name '.git' -o -name 'scripts' -o -name 'README.md' -o -name '.vscode' -o -name '.github' -o -name '.idea' -o -name '.editorconfig' -o -name '.gitattributes' -o -name '.gitignore' -o -name 'LICENSE' -o -name 'Makefile' \) -print0)
}

# print_preview: show what would be deleted
print_preview() {
    if [ ${#to_delete[@]} -eq 0 ]; then
        echo 'Nothing to delete.'
        exit 0
    fi
    echo 'Files and directories that would be removed:'
    for p in "${to_delete[@]}"; do
        printf '%s\n' "${p#./}"
    done
}

# main: orchestrate preview logic
main() {
    check_context
    find_targets
    print_preview
}

main "$@"
