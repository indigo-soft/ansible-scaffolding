#!/usr/bin/env bash
# Bootstrap script: initial server setup and connection validation
set -euo pipefail

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

die() {
    printf "${RED}❌ %s${NC}\n" "$*" >&2
    exit 1
}

info() {
    printf "${GREEN}ℹ️  %s${NC}\n" "$*"
}

warn() {
    printf "${YELLOW}⚠️  %s${NC}\n" "$*"
}

usage() {
    cat <<EOF
Usage: $0 <hostname>

Bootstrap a new server:
  1. Run ansible bootstrap playbook with host_vars
  2. Comment out all variables in host_vars/<env>/<hostname>.yml
  3. Test connection without those variables
  4. If successful - keep commented; if failed - restore variables

Example:
  $0 staging-1.server
EOF
    exit 1
}

# Find host_vars file
find_host_vars_file() {
    local hostname="$1"
    local found
    found=$(find host_vars -type f -name "${hostname}.yml" 2>/dev/null | head -n1)
    if [[ -z "$found" ]]; then
        die "Host vars file not found for: ${hostname}"
    fi
    echo "$found"
}

# Create backup of host_vars file
create_backup() {
    local target_file="$1"
    local backup_file
    backup_file="${target_file}.backup-$(date +%s)"
    cp "$target_file" "$backup_file"
    info "Created backup: ${backup_file}"
    echo "$backup_file"
}

# Restore backup and cleanup
restore_backup() {
    local backup_file="$1"
    local target_file="$2"

    warn "Restoring variables from backup due to error..."

    # Restore from backup
    cp "$backup_file" "$target_file"
    info "Variables restored from backup"

    # Verify restoration
    if cmp -s "$backup_file" "$target_file"; then
        info "Verification: restored file matches backup ✓"
        rm -f "$backup_file"
        info "Backup removed after successful restoration"
    else
        die "Verification failed: restored file does not match backup. Manual check required."
    fi
}

# Run bootstrap playbook
run_bootstrap_playbook() {
    local host_name="$1"
    info "Running bootstrap playbook for ${host_name}..."
    if ! ansible-playbook playbooks/bootstrap.yml -e "target_host=${host_name}" -i inventory/hosts.yml; then
        return 1
    fi
    info "Bootstrap playbook completed successfully"
    return 0
}

# Comment out all non-comment lines in file
comment_out_variables() {
    local file="$1"
    info "Commenting out variables in ${file}..."
    sed -i.tmp 's/^\([^#[:space:]].*\)$/# \1/' "$file"
    rm -f "${file}.tmp"
    info "Variables commented out"
}

# Test connection without bootstrap variables
test_connection() {
    local host_name="$1"
    info "Testing connection to ${host_name} without bootstrap variables..."
    sleep 2  # Give SSH time to settle

    if ansible "$host_name" -m ping -i inventory/hosts.yml &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Main bootstrap workflow
main() {
    # Validate arguments
    [[ $# -eq 1 ]] || usage
    local host_name="$1"

    # Find and backup host_vars file
    local host_vars_file
    host_vars_file=$(find_host_vars_file "$host_name")
    info "Found host vars file: ${host_vars_file}"

    local backup_file
    backup_file=$(create_backup "$host_vars_file")

    # Step 1: Run bootstrap playbook
    if ! run_bootstrap_playbook "$host_name"; then
        restore_backup "$backup_file" "$host_vars_file"
        die "Bootstrap playbook failed. Check Ansible output above."
    fi

    # Step 2: Comment out variables
    comment_out_variables "$host_vars_file"

    # Step 3: Test connection
    if test_connection "$host_name"; then
        info "${GREEN}✅ Bootstrap successful!${NC}"
        info "Server ${host_name} is accessible with normal connection settings"
        info "Variables in ${host_vars_file} remain commented out"
        rm -f "$backup_file"
        info "Backup removed: ${backup_file}"
        exit 0
    else
        restore_backup "$backup_file" "$host_vars_file"
        die "Bootstrap may have issues. Server ${host_name} not accessible without explicit host_vars. Check configuration manually."
    fi
}

main "$@"
