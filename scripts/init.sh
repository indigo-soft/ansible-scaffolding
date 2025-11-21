#!/usr/bin/env bash
set -euo pipefail

vault_password_file="${1:-.vault}"

# create_dirs: ensure basic Ansible project directories exist
create_dirs() {
  mkdir -p inventory group_vars host_vars playbooks files templates roles
}

# render_template: copy a template file from templates/init into a destination,
# replacing the __VAULT_FILE__ placeholder with the configured vault file.
render_template() {
  local src="$1" dst="$2"
  if [ ! -f "$src" ]; then
    printf "[WARNING]: template not found: %s\n" "$src" >&2
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  sed "s|__VAULT_FILE__|${vault_password_file}|g" "$src" > "$dst"
}

# create_ansible_cfg: write ansible.cfg from template
create_ansible_cfg() {
  render_template "$(dirname "$0")/templates/init/ansible.cfg" ./ansible.cfg
  chmod 644 ./ansible.cfg
  export ANSIBLE_CONFIG=./ansible.cfg
}

# create_site_yml: write the top-level site playbook from template
create_site_yml() {
  render_template "$(dirname "$0")/templates/init/site.yml" ./site.yml
}

# create_inventory: write inventory hosts file from template
create_inventory() {
  mkdir -p inventory
  render_template "$(dirname "$0")/templates/init/inventory_hosts.ini" inventory/hosts.ini
}

# create_group_vars: write group_vars/all.yml from template
create_group_vars() {
  mkdir -p group_vars
  render_template "$(dirname "$0")/templates/init/group_vars_all.yml" group_vars/all.yml
}

# run_optional_make: call Makefile targets if Makefile exists
run_optional_make() {
  if [ -f Makefile ]; then
    make --no-print-directory vault || true
  fi
}

# set_permissions: apply safe, non-world-writable perms to repository files
set_permissions() {
  chmod -R a-w . || true
}

# main: orchestrate init
main() {
  # Abort if ansible.cfg already exists to avoid overwriting an existing configuration
  if [ -f ./ansible.cfg ]; then
    printf "%b\n" "\033[31m[ERROR]: ansible.cfg already exists in the current directory.\033[0m" >&2
    printf "%b\n" "\033[31mInit aborted to avoid overwriting existing configuration.\033[0m" >&2
    exit 1
  fi

  create_dirs
  create_ansible_cfg
  create_site_yml
  create_inventory
  create_group_vars
  run_optional_make
  set_permissions
  printf "%s\n" "✅ Project structure created"
}

main "$@"
