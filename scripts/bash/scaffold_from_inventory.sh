#!/usr/bin/env bash
set -euo pipefail

# die: print error and exit
die() {
  printf "\033[31m[ERROR]: %s\033[0m\n" "$1" >&2
  exit 1
}

# validate_inventory: check if inventory file exists
validate_inventory() {
  local inv_file="$1"
  [ -f "$inv_file" ] || die "Inventory file '$inv_file' not found."
}

# run_scaffold: execute Python scaffolding script
run_scaffold() {
  local inv_file="$1"
  python3 scripts/python/scaffold_from_inventory.py "$inv_file"
}

# main: orchestrate scaffold generation
main() {
  local inv_file="${1:-inventory/hosts.yml}"
  validate_inventory "$inv_file"
  run_scaffold "$inv_file"
}

main "$@"
