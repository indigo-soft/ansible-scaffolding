#!/usr/bin/env bash
set -euo pipefail

role_name="${1:-}"

script_dir=""
template_root=""
dest_root=""

# die: print an error message and exit with optional code
die() {
    printf "%s\n" "❌ $1" >&2
    exit ${2:-1}
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
    script_dir="$(cd "$(dirname "$0")" && pwd)"
    template_root="$script_dir/templates/role"
    dest_root="./roles/$role_name"

    if [ ! -d "$template_root" ]; then
        die "Templates directory not found: $template_root"
    fi
}

# copy_templates: recursively copy template files to the new role,
# replacing the __ROLE__ placeholder
copy_templates() {
    find "$template_root" -type f -print0 | while IFS= read -r -d '' tpl; do
        rel_path="${tpl#$template_root/}"
        dest="$dest_root/$rel_path"
        mkdir -p "$(dirname "$dest")"
        sed "s|__ROLE__|${role_name}|g" "$tpl" > "$dest"
    done
}

# install_group_vars: place group_vars/webservers.yml from templates
install_group_vars() {
    mkdir -p group_vars
    if [ -f "$template_root/group_vars/webservers.yml" ]; then
        sed "s|__ROLE__|${role_name}|g" "$template_root/group_vars/webservers.yml" > group_vars/webservers.yml
    fi
}

# main: entrypoint that validates args and runs setup + copy
main() {
    if [ -z "$role_name" ]; then
        usage
        die "Role name required"
    fi

    validate_role_name
    setup_paths
    copy_templates
    install_group_vars

    printf "✅ Role %s scaffolded\n" "$role_name"
}

main "$@"
