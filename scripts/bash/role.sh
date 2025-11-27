#!/usr/bin/env bash
set -euo pipefail

role_name="${1:-}"

script_dir=""
template_root=""
dest_root=""

# die: print an error message and exit with optional code
die() {
    printf "❌ %s\n" "$1" >&2
    exit "${2:-1}"
}

# usage: show short usage help for the script
usage() {
    cat <<EOF
Usage: $(basename "$0") <role-name>
Scaffolds a new role from templates in scripts/templates/role
EOF
}

# validate_role_name: ensure the provided role name is safe
validate_role_name() {
    # allow letters, numbers, underscore and hyphen
    if [[ ! "$role_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        die "Invalid role name: '$role_name'. Use [a-zA-Z0-9_-]+"
    fi
}

# setup_paths: compute script and template paths, set destination root
setup_paths() {
    script_dir="$(cd "$(dirname "$0")/.." && pwd)"
    template_root="$script_dir/templates/role"
    dest_root="./roles/$role_name"

    if [ ! -d "$template_root" ]; then
        die "Templates directory not found: $template_root"
    fi
}

# copy_templates: recursively copy template files to the new role,
# replacing the __ROLE__ placeholder
copy_templates() {
    # Copy templates but skip molecule tests by default; molecule tests
    # will be created explicitly via the create command.
    find "$template_root" -type f -print0 | while IFS= read -r -d '' tpl; do
        rel_path="${tpl#"$template_root"/}"
        # skip any molecule templates
        case "$rel_path" in
            molecule/*) continue ;;
        esac
        dest="$dest_root/$rel_path"
        mkdir -p "$(dirname "$dest")"
        sed "s|__ROLE__|${role_name}|g" "$tpl" > "$dest"
    done
}

# main: entrypoint that validates args and runs setup + copy
main() {
    if [ -z "$role_name" ]; then
        usage
        die "Role name required"
    fi

    validate_role_name
    setup_paths

    # If the destination role directory already exists, abort with a red error.
    if [ -d "$dest_root" ]; then
        printf "%b\n" "\033[31m[ERROR]: Role '$role_name' already exists.\033[0m" >&2
        exit 1
    fi
    copy_templates
    #install_group_vars

    # encrypt role-related YAML files (defaults, vars, group_vars)
    make encrypt

    printf "✅ Role %s scaffolded and encrypted\n" "$role_name"
}

main "$@"
