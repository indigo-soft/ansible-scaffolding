#!/usr/bin/env bash
set -euo pipefail

# die: print error and exit
die() {
  printf "\033[31m❌ %s\033[0m\n" "$1" >&2
  exit 1
}

# info: print info message
info() {
  printf "\033[32mℹ️  %s\033[0m\n" "$1"
}

# parse_mode: determine formatting mode (write or check)
parse_mode() {
  local mode="$1"
  case "$mode" in
    write|--write) echo "--write" ;;
    check|--check) echo "--check" ;;
    *) die "Unknown mode '$mode'. Use 'write' or 'check'" ;;
  esac
}

# detect_prettier: find prettier command
detect_prettier() {
  if command -v npx >/dev/null 2>&1; then
    echo "npx prettier"
  elif command -v prettier >/dev/null 2>&1; then
    echo "prettier"
  else
    die "Prettier not found. Install: npm i -D prettier (or use npx prettier)"
  fi
}

# collect_yaml_files: gather YAML files from key directories
collect_yaml_files() {
  shopt -s globstar nullglob
  local patterns=(
    playbooks/**/*.yml playbooks/**/*.yaml
    inventory/**/*.yml inventory/**/*.yaml
    group_vars/**/*.yml group_vars/**/*.yaml
    host_vars/**/*.yml host_vars/**/*.yaml
    roles/**/*.yml roles/**/*.yaml
  )
  local files=()
  for pattern in "${patterns[@]}"; do
    for file in $pattern; do
      [ -f "$file" ] && files+=("$file")
    done
  done
  printf "%s\n" "${files[@]}"
}

# run_yamllint: validate YAML files if yamllint is available
run_yamllint() {
  local -a files=("$@")

  if ! command -v npx >/dev/null 2>&1 || ! npx yamllint --version >/dev/null 2>&1; then
    return 0
  fi

  info "Checking YAML validity (yamllint)..."
  if ! npx yamllint "${files[@]}" 2>&1; then
    die "yamllint found errors. Fix the files and run again."
  fi
}

# run_prettier: format YAML files with Prettier
run_prettier() {
  local action="$1"
  shift
  local -a files=("$@")
  local prettier_cmd
  prettier_cmd=$(detect_prettier)

  info "Running Prettier (${action#--}) for ${#files[@]} YAML files..."
  $prettier_cmd "$action" "${files[@]}"
  info "Done."
}

# main: orchestrate formatting process
main() {
  local mode="${1:-write}"
  local action
  action=$(parse_mode "$mode")

  local -a files
  mapfile -t files < <(collect_yaml_files)

  if [ ${#files[@]} -eq 0 ]; then
    info "No YAML files to format"
    exit 0
  fi

  run_yamllint "${files[@]}"
  run_prettier "$action" "${files[@]}"
}

main "$@"
