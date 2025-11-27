#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-encrypt}"
VAULT_PASS_FILE="${2:-.vault}"

usage() { echo "Usage: $0 <encrypt|decrypt> [vault_pass_file]"; exit 2; }
die() { printf "\033[31m❌ %s\033[0m\n" "$1" >&2; exit 1; }
info() { printf "\033[32mℹ️  %s\033[0m\n" "$1"; }

case "$MODE" in
  encrypt|decrypt) ;;
  *) usage ;;
esac

ensure_vault_pass() {
  if [ ! -f "$VAULT_PASS_FILE" ]; then
    head -c 32 /dev/urandom | base64 > "$VAULT_PASS_FILE"
    chmod 600 "$VAULT_PASS_FILE"
    info "Created vault password: $VAULT_PASS_FILE"
  fi
}

is_encrypted() {
  head -n 1 -- "$1" 2>/dev/null | grep -q "^\$ANSIBLE_VAULT;"
}

find_ansible_vault() {
  if command -v ansible-vault >/dev/null 2>&1; then
    echo "ansible-vault"
  elif [ -x "$HOME/.local/bin/ansible-vault" ]; then
    echo "$HOME/.local/bin/ansible-vault"
  else
    die "ansible-vault not found. Install: pip3 install --user ansible"
  fi
}

collect_targets() {
  local out_file="$1"
  # group_vars and host_vars
  find group_vars host_vars -type f \( -name "*.yml" -o -name "*.yaml" \) 2>/dev/null >>"$out_file" || true
  # roles/**/defaults/*.yml|yaml (recursive)
  find roles -type f -path "*/defaults/*" \( -name "*.yml" -o -name "*.yaml" \) 2>/dev/null >>"$out_file" || true
  # unique + stable order
  sort -u -o "$out_file" "$out_file" || true
}

main() {
  ensure_vault_pass

  local ansible_vault_cmd
  ansible_vault_cmd="$(find_ansible_vault)"

  local tmp_list
  tmp_list="$(mktemp)"
  trap 'rm -f "$tmp_list"' EXIT

  collect_targets "$tmp_list"

  if [ ! -s "$tmp_list" ]; then
    info "No files found in group_vars, host_vars, or roles/**/defaults"
    exit 0
  fi

  local total=0
  local changed=0
  local skipped=0
  local action_word
  if [ "$MODE" = "encrypt" ]; then action_word="encrypted"; else action_word="decrypted"; fi

  while IFS= read -r file; do
    [ -f "$file" ] || continue
    total=$((total + 1))

    if [ "$MODE" = "encrypt" ]; then
      if is_encrypted "$file"; then
        info "Already encrypted, skipping: $file"
        skipped=$((skipped + 1))
      else
        "$ansible_vault_cmd" encrypt "$file" --vault-password-file "$VAULT_PASS_FILE" --encrypt-vault-id default >/dev/null
        info "Encrypted: $file"
        changed=$((changed + 1))
      fi
    else
      if is_encrypted "$file"; then
        "$ansible_vault_cmd" decrypt "$file" --vault-password-file "$VAULT_PASS_FILE" >/dev/null
        info "Decrypted: $file"
        changed=$((changed + 1))
      else
        info "Not encrypted, skipping: $file"
        skipped=$((skipped + 1))
      fi
    fi
  done < "$tmp_list"

  info "Total processed: $total, $action_word: $changed, skipped: $skipped"
}

main "$@"
