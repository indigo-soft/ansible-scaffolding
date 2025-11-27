#!/usr/bin/env bash
set -euo pipefail

PLAYBOOK="playbooks/site.yml"

# die: print error and exit
die() {
  printf "\033[31m[ERROR]: %s\033[0m\n" "$1" >&2
  exit 1
}

# warn: print warning message
warn() {
  printf "\033[31m[WARNING]: %s\033[0m\n" "$1" >&2
}

# info: print info message
info() {
  printf "\033[32m[INFO]: %s\033[0m\n" "$1"
}

# collect_yaml_files: gather YAML files from key directories
collect_yaml_files() {
  shopt -s globstar nullglob
  local files=(
    group_vars/**/*.yml group_vars/**/*.yaml
    host_vars/**/*.yml host_vars/**/*.yaml
    playbooks/**/*.yml playbooks/**/*.yaml
    roles/**/*.yml roles/**/*.yaml
  )
  printf "%s\n" "${files[@]}"
}

# run_yamllint: validate YAML syntax and structure
run_yamllint() {
  if ! command -v npx >/dev/null 2>&1 || ! npx yamllint --version >/dev/null 2>&1; then
    return 0
  fi

  info "Running yamllint on YAML files..."
  local yaml_files
  mapfile -t yaml_files < <(collect_yaml_files)

  if [ ${#yaml_files[@]} -eq 0 ]; then
    return 0
  fi

  npx yamllint "${yaml_files[@]}" || die "yamllint found errors in YAML files."
}

# check_ansible_lint: verify ansible-lint is available
check_ansible_lint() {
  if ! command -v ansible-lint >/dev/null 2>&1; then
    warn "ansible-lint not found."
    echo "Install: pip3 install --user ansible-lint  OR pipx install ansible-lint" >&2
    echo "Ensure \"~/.local/bin\" is in your PATH if you used --user." >&2
    exit 1
  fi
}

# run_ansible_lint: validate playbook with ansible-lint
run_ansible_lint() {
  ansible-lint "$PLAYBOOK"
}

# main: orchestrate linting process
main() {
  run_yamllint
  check_ansible_lint
  run_ansible_lint
}

main "$@"
