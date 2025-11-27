#!/usr/bin/env bash
set -euo pipefail

INV="inventory"

# detect_python: find available Python interpreter
detect_python() {
  command -v python3 2>/dev/null || command -v python 2>/dev/null || true
}

# run_ping: execute ansible ping with detected Python interpreter
run_ping() {
  local py
  py=$(detect_python)

  if [ -n "$py" ]; then
    ansible -i "$INV" all -m ping -e "ansible_python_interpreter=$py"
  else
    ansible -i "$INV" all -m ping
  fi
}

# main: orchestrate ping check
main() {
  run_ping
}

main "$@"
