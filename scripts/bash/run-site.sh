#!/usr/bin/env bash
set -euo pipefail

PLAYBOOK="playbooks/site.yml"
INVENTORY="inventory"

# usage: show usage info
usage() {
  printf "Usage: %s [run|check]\n" "$(basename "$0")" >&2
}

# run_playbook: execute ansible-playbook with the given mode
run_playbook() {
  local mode="$1"
  case "$mode" in
    run|--run)
      ansible-playbook -i "$INVENTORY" "$PLAYBOOK"
      ;;
    check|--check|--dry-run)
      ansible-playbook -i "$INVENTORY" "$PLAYBOOK" --check
      ;;
    *)
      usage
      exit 2
      ;;
  esac
}

# main: orchestrate execution
main() {
  local mode="${1:-run}"
  run_playbook "$mode"
}

main "$@"
