#!/usr/bin/env bash
set -euo pipefail

# die: print error and exit
die() {
    printf "%s\n" "ERROR: $1" >&2
    exit ${2:-1}
}

# usage: show usage info
usage() {
    cat <<EOF
Usage: $(basename "$0") <file-to-edit> [vault-password-file]
Edits the given file with the preferred editor (VISUAL, EDITOR, or from shell config).
Defaults to 'nano' when no editor is found.
EOF
}

# parse_shell_config: look for exported VISUAL/EDITOR in typical shell rc files
parse_shell_config() {
    local rc_files=("$HOME/.bashrc" "$HOME/.profile" "$HOME/.bash_profile" "/etc/profile")
    local line value
    for f in "${rc_files[@]}"; do
        [ -r "$f" ] || continue
        # prefer VISUAL then EDITOR
        if line=$(grep -m1 -E "^\s*export\s+VISUAL=" "$f" 2>/dev/null || true); then
            value=$(printf "%s" "$line" | sed -E 's/^\s*export\s+VISUAL=//; s/^"//; s/"$//')
            printf "%s" "$value"
            return 0
        fi
        if line=$(grep -m1 -E "^\s*export\s+EDITOR=" "$f" 2>/dev/null || true); then
            value=$(printf "%s" "$line" | sed -E 's/^\s*export\s+EDITOR=//; s/^"//; s/"$//')
            printf "%s" "$value"
            return 0
        fi
    done
    return 1
}

# get_editor: determine the editor to use
get_editor() {
    # 1) VISUAL env
    if [ -n "${VISUAL:-}" ]; then
        printf "%s" "$VISUAL"
        return 0
    fi
    # 2) EDITOR env
    if [ -n "${EDITOR:-}" ]; then
        printf "%s" "$EDITOR"
        return 0
    fi
    # 3) parse shell config files
    if editor_from_config=$(parse_shell_config); then
        if [ -n "$editor_from_config" ]; then
            printf "%s" "$editor_from_config"
            return 0
        fi
    fi
    # 4) fallback to nano, then vi
    if command -v nano >/dev/null 2>&1; then
        printf "nano"
        return 0
    fi
    if command -v vi >/dev/null 2>&1; then
        printf "vi"
        return 0
    fi
    # last resort
    printf "ed"
}

# main: validate args and exec ansible-vault edit with chosen editor
main() {
    if [ $# -lt 1 ]; then
        usage
        die "file to edit not specified"
    fi
    local target="$1"
    local vault_file="${2:-.vault}"
    if [ ! -f "$target" ]; then
        die "target file does not exist: $target"
    fi

    editor=$(get_editor)
    export EDITOR="$editor"

    # run ansible-vault edit with the selected editor
    ansible-vault edit "$target" --vault-password-file "$vault_file"
}

main "$@"
