#!/usr/bin/env bash
set -euo pipefail


# usage: show usage info for the script
usage() {
    cat <<EOF
Usage: $(basename "$0") <role-name>
Encrypts YAML files for the given role and project group_vars using ansible-vault.
EOF
}

# die: print error and exit
die() {
    printf "ERROR: %s\n" "$1" >&2
    local rc="${2:-1}"
    exit "$rc"
}

# ensure_vault_file: create vault password file if missing
ensure_vault_file() {
    if [ ! -f "$vault_file" ]; then
        head -c 32 /dev/urandom | base64 > "$vault_file"
        chmod 600 "$vault_file"
    fi
}

# find_yaml_targets: collect YAML files to encrypt
find_yaml_targets() {
    mapfile -d '' -t enc_targets < <(find "$role_dir" group_vars -type f \( -name "*.yml" -o -name "*.yaml" \) -print0 2>/dev/null || true)
}

# encrypt_files: encrypt all found YAML files unless already encrypted
encrypt_files() {
    if [ ${#enc_targets[@]} -eq 0 ]; then
        echo "Nothing to encrypt for role '$role_name'."
        exit 0
    fi

    echo "Encrypting ${#enc_targets[@]} files for role '$role_name'..."
    for f in "${enc_targets[@]}"; do
        if head -n1 "$f" 2>/dev/null | grep -q "ANSIBLE_VAULT"; then
            echo "- Skipping already-encrypted: ${f#./}"
            continue
        fi
        ansible-vault encrypt "$f" --vault-password-file "$vault_file" --encrypt-vault-id default
        echo "- Encrypted: ${f#./}"
    done
    echo "Encryption complete."
}

# main: orchestrate encryption logic
main() {
    if [ $# -lt 1 ]; then
        usage
        die "role name required"
    fi

    role_name="$1"
    vault_file="${2:-.vault}"
    role_dir="./roles/$role_name"

    if [ ! -d "$role_dir" ]; then
        die "role directory not found: $role_dir"
    fi

    ensure_vault_file
    find_yaml_targets
    encrypt_files
}

main "$@"
