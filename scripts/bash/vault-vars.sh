#!/usr/bin/env bash
set -euo pipefail

# usage: show usage info
usage() {
  cat <<EOF
Usage: $0 <encrypt|decrypt> [vault_password_file]

Actions:
  encrypt   Encrypt all YAML files in group_vars/ (including subdirectories)
  decrypt   Decrypt all YAML files in group_vars/ (including subdirectories)

Environment/Args:
  vault_password_file: path to vault password file (default: .vault)
EOF
}

# info: print info message
info() {
  printf "\033[32m[INFO]: %s\033[0m\n" "$1"
}

# warn: print warning message
warn() {
  printf "\033[33m[WARN]: %s\033[0m\n" "$1" >&2
}

# collect_yaml_files: find all YAML files in group_vars
collect_yaml_files() {
  {
    find group_vars -type f -name "*.yml" 2>/dev/null
    find group_vars -type f -name "*.yaml" 2>/dev/null
  } | sort -u
}

# is_encrypted: check if file is already encrypted
is_encrypted() {
  local file="$1"
  head -n1 "$file" 2>/dev/null | grep -q '^\$ANSIBLE_VAULT;'
}

# ensure_vault_pass: create vault password file if missing
ensure_vault_pass() {
  local vault_pass_file="$1"
  if [ ! -f "$vault_pass_file" ]; then
    head -c 32 /dev/urandom | base64 > "$vault_pass_file"
    chmod 600 "$vault_pass_file"
  fi
}

# encrypt_vault: encrypt all YAML files in group_vars
encrypt_vault() {
  local vault_pass_file="$1"
  ensure_vault_pass "$vault_pass_file"

  local encrypted=0
  local skipped=0
  local total=0

  # Try to find ansible-vault in PATH or common locations
  local ansible_vault_cmd
  if command -v ansible-vault >/dev/null 2>&1; then
    ansible_vault_cmd="ansible-vault"
  elif [ -x "$HOME/.local/bin/ansible-vault" ]; then
    ansible_vault_cmd="$HOME/.local/bin/ansible-vault"
  else
    printf "\033[31m[ERROR]: ansible-vault not found. Install: pip3 install --user ansible\033[0m\n" >&2
    exit 1
  fi

  # Process all YAML files
  local file
  for file in $(find group_vars -type f \( -name "*.yml" -o -name "*.yaml" \) 2>/dev/null | sort -u); do
    total=$((total + 1))
    if is_encrypted "$file"; then
      info "Skipping already encrypted: $file"
      skipped=$((skipped + 1))
    else
      info "Encrypting: $file"
      "$ansible_vault_cmd" encrypt "$file" --vault-password-file "$vault_pass_file" --encrypt-vault-id default
      encrypted=$((encrypted + 1))
    fi
  done

  if [ $total -eq 0 ]; then
    warn "No YAML files found in group_vars/"
  else
    info "Encrypted: $encrypted, Skipped: $skipped"
  fi
}

# decrypt_vault: decrypt all YAML files in group_vars
decrypt_vault() {
  local vault_pass_file="$1"

  local decrypted=0
  local skipped=0
  local total=0

  # Try to find ansible-vault in PATH or common locations
  local ansible_vault_cmd
  if command -v ansible-vault >/dev/null 2>&1; then
    ansible_vault_cmd="ansible-vault"
  elif [ -x "$HOME/.local/bin/ansible-vault" ]; then
    ansible_vault_cmd="$HOME/.local/bin/ansible-vault"
  else
    printf "\033[31m[ERROR]: ansible-vault not found. Install: pip3 install --user ansible\033[0m\n" >&2
    exit 1
  fi

  # Process all YAML files
  local file
  for file in $(find group_vars -type f \( -name "*.yml" -o -name "*.yaml" \) 2>/dev/null | sort -u); do
    total=$((total + 1))
    if is_encrypted "$file"; then
      info "Decrypting: $file"
      "$ansible_vault_cmd" decrypt "$file" --vault-password-file "$vault_pass_file"
      decrypted=$((decrypted + 1))
    else
      info "Skipping already decrypted: $file"
      skipped=$((skipped + 1))
    fi
  done

  if [ $total -eq 0 ]; then
    warn "No YAML files found in group_vars/"
  else
    info "Decrypted: $decrypted, Skipped: $skipped"
  fi
}

# handle_action: dispatch to appropriate vault operation
handle_action() {
  local action="$1"
  local vault_pass_file="$2"

  case "$action" in
    encrypt)
      encrypt_vault "$vault_pass_file"
      ;;
    decrypt)
      decrypt_vault "$vault_pass_file"
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
}

# main: orchestrate vault operations
main() {
  local action="${1:-}"
  local vault_pass_file="${2:-.vault}"

  if [ -z "$action" ]; then
    usage >&2
    exit 2
  fi

  handle_action "$action" "$vault_pass_file"
}

main "$@"
