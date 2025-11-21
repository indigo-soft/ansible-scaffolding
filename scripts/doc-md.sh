#!/usr/bin/env bash
set -euo pipefail

# check_prereqs: ensure helper commands are present
check_prereqs() {
    command -v tree >/dev/null 2>&1 || die "Please install tree: sudo apt install tree"
}

# die: print an error message and exit
die() {
    printf "❌ %s\n" "$1" >&2
    exit "${2:-1}"
}

# render_doc: build README.md by concatenating template fragments
render_doc() {
    local script_dir template_dir
    script_dir="$(cd "$(dirname "$0")" && pwd)"
    template_dir="$script_dir/templates/doc-md"

    if [ ! -d "$template_dir" ]; then
        die "Templates directory not found: $template_dir"
    fi

    mkdir -p ./docs

    cat "$template_dir/readme_intro.md" \
    "$template_dir/commands.md" \
    "$template_dir/wsl_note.md" \
    "$template_dir/ansible_lint.md" > ./docs/README.md
}

# main: entrypoint
main() {
    check_prereqs
    render_doc
    printf "%s\n" "✅ README.md updated"
}

main "$@"
