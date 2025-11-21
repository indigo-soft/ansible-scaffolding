#!/usr/bin/env bash
set -euo pipefail

# Color constants (use $'...' so backslash escapes become real ANSI bytes)
RED=$'\033[31m'
YELLOW=$'\033[33m'
GREEN=$'\033[32m'
NC=$'\033[0m'
# check_molecule: ensure molecule is installed
check_molecule() {
    command -v molecule >/dev/null 2>&1 || {
        printf "%s\n" "${RED}[ERROR]: molecule not found.${NC}"
        echo "Install: pip3 install --user molecule"
        exit 1
    }
}

# check_roles: ensure there are roles to test

# check_roles: ensure there are roles to test
check_roles() {
    # More robustly check for at least one directory under roles/
    if [ ! -d "roles" ]; then
        printf "%s\n" "${YELLOW}[WARNING]: No 'roles' directory found. Stopping.${NC}" 1>&2
        exit 1
    fi

    if ! find roles -mindepth 1 -maxdepth 1 -type d -print -quit | grep -q .; then
        printf "%s\n" "${YELLOW}[WARNING]: No roles found in ./roles. Stopping.${NC}" 1>&2
        exit 1
    fi
}

# check_roles_dir: ensure the roles directory exists
check_roles_dir() {
    if ! [ -d roles ]; then
        printf "%s\n" "${YELLOW}[WARNING]: The 'roles' directory does not exist. Stopping.${NC}" 1>&2
        exit 1
    fi
}

# check_tests: ensure there are molecule tests

# check_tests: ensure there are molecule tests
check_tests() {
    # Ensure at least one role contains a Molecule scenario/tests under roles/*/molecule/default
    if [ ! -d "roles" ]; then
        printf "%s\n" "${YELLOW}[WARNING]: The 'roles' directory does not exist. Stopping.${NC}" 1>&2
        exit 1
    fi

    local found=0
    for r in roles/*; do
        [ -d "$r" ] || continue
        if [ -f "$r/molecule/default/molecule.yml" ] || [ -f "$r/molecule/default/verify.yml" ] || [ -d "$r/molecule/default/tests" ]; then
            found=1
            break
        fi
    done

    if [ "$found" -eq 0 ]; then
        printf "%s\n" "${YELLOW}[WARNING]: No Molecule tests found in any role under ./roles. Stopping.${NC}" 1>&2
        exit 1
    fi
}

# create_molecule_scenario: initialize a Molecule scenario for a role
create_molecule_scenario() {
    local role_name="$1"

    if [ -z "$role_name" ]; then
        printf "%s\n" "${RED}[ERROR]: Role name not provided.${NC}"
        exit 1
    fi

    if [ ! -d "roles/$role_name" ]; then
        printf "%s\n" "${RED}[ERROR]: Role directory roles/$role_name does not exist.${NC}"
        printf "%s\n" "To create the role run: make role $role_name"
        exit 1
    fi

    cd "roles/$role_name"

    if [ -d "molecule/default" ]; then
        printf "%s\n" "${YELLOW}[INFO]: Molecule scenario already exists for role '$role_name'.${NC}"
    else
        molecule init scenario default
        printf "%s\n" "${GREEN}[INFO]: Molecule scenario initialized for role '$role_name'.${NC}"
    fi
}

# remove_molecule_tests: remove molecule tests for a role or for all roles
remove_molecule_tests() {
    local role_name="${1:-}"

    if [ ! -d "roles" ]; then
        printf "%s\n" "${YELLOW}[WARNING]: 'roles' directory not found. Nothing to remove.${NC}"
        return 0
    fi

    # helper: confirm action unless FORCE=1
    confirm() {
        # Try to prompt the user. Prefer the current stdin/stdout if they are a TTY,
        # otherwise fall back to /dev/tty so the prompt still works when invoked
        # through `make` or other wrappers that may not have a TTY on stdout.
        local prompt="$1"
        local ans
            if [ -t 0 ] || [ -t 1 ]; then
            printf "%s" "$prompt"
            read -r ans
        elif [ -e /dev/tty ]; then
            # read from the controlling terminal
            printf "%s" "$prompt" > /dev/tty
            read -r ans < /dev/tty
        else
            printf "%s\n" "${RED}[ERROR]: No TTY available for confirmation. Aborting.${NC}"
            exit 1
        fi

        case "${ans,,}" in
            y|yes) return 0 ;;
            *) printf "%s\n" "${YELLOW}[INFO]: Aborted by user.${NC}"; return 1 ;;
        esac
    }

    if [ -n "$role_name" ]; then
            if [ ! -d "roles/$role_name" ]; then
            printf "%s\n" "${RED}[ERROR]: Role directory roles/$role_name does not exist.${NC}"
            exit 1
        fi
        if [ -d "roles/$role_name/molecule" ]; then
                if confirm "Remove Molecule tests for role '$role_name'? [y/N]: "; then
                rm -rf -- "roles/$role_name/molecule"
                printf "%s\n" "${GREEN}[INFO]: Removed Molecule tests for role '$role_name'.${NC}"
            else
                return 1
            fi
        else
            printf "%s\n" "${YELLOW}[INFO]: No Molecule tests found for role '$role_name'.${NC}"
        fi
    else
        # remove for all roles
        local removed=0
        # collect roles that have molecule directories
        local -a roles_to_remove=()
        local d role_dir role_basename
        for d in roles/*/; do
            [ -d "$d" ] || continue
            role_dir="${d%/}"
            role_basename="${role_dir##*/}"
            if [ -d "$role_dir/molecule" ]; then
                roles_to_remove+=("$role_basename")
            fi
        done

        if [ ${#roles_to_remove[@]} -eq 0 ]; then
            printf "%s\n" "${YELLOW}[INFO]: No Molecule tests found in any role.${NC}"
            return 0
        fi

        printf "%s\n" "Found Molecule tests in the following roles:"
        for r in "${roles_to_remove[@]}"; do
            printf " - %s\n" "$r"
        done

        if confirm "Remove Molecule tests for ALL listed roles? [y/N]: "; then
            local r
            for r in "${roles_to_remove[@]}"; do
                rm -rf -- "roles/$r/molecule"
                printf "%s\n" "${GREEN}[INFO]: Removed Molecule tests for role '$r'.${NC}"
                removed=1
            done
        else
            printf "%s\n" "${YELLOW}[INFO]: Aborted by user. No directories removed.${NC}"
            return 1
        fi
        if [ "$removed" -eq 0 ]; then
            printf "%s\n" "${YELLOW}[INFO]: No Molecule tests found in any role.${NC}"
        fi
    fi
}

# list_molecule_instances: list molecule instances for a role
list_molecule_instances() {
    local role_name="${1:-}"

    if [ -z "$role_name" ]; then
        printf "%s\n" "${RED}[ERROR]: Role name required. Usage: $0 list <role>${NC}"
        exit 1
    fi

    if [ ! -d "roles/$role_name" ]; then
        printf "\033[31m[ERROR]: Role directory roles/%s does not exist.\033[0m\n" "$role_name"
        printf "To create the role run:\n  make role %s\n" "$role_name"
        exit 1
    fi

    check_molecule

    if [ ! -f "roles/$role_name/molecule/default/molecule.yml" ]; then
        printf "%s\n" "${RED}[ERROR]: molecule.yml not found in roles/$role_name/molecule/default/.${NC}"
        exit 1
    fi

    (cd "roles/$role_name" && molecule list)
}

# test_molecule_for_role: run `molecule test` for a single role (required)
test_molecule_for_role() {
    local role_name="${1:-}"

    if [ -z "$role_name" ]; then
        printf "%s\n" "${RED}[ERROR]: Role name required. Usage:  make molecule-test <role>${NC}"
        exit 1
    fi

    if [ ! -d "roles/$role_name" ]; then
        printf "%s\n" "${RED}[ERROR]: Role directory roles/$role_name does not exist.${NC}"
        printf "%s\n" "To create the role run:\n  make role $role_name"
        exit 1
    fi

    check_molecule

        if [ ! -f "roles/$role_name/molecule/default/molecule.yml" ] && \
       ! [ -f "roles/$role_name/molecule/default/verify.yml" ] && \
       ! [ -d "roles/$role_name/molecule/default/tests" ]; then
        printf "%s\n" "${RED}[ERROR]: No Molecule scenario/tests found in roles/$role_name/molecule/default/.${NC}"
        exit 1
    fi

    (cd "roles/$role_name" && molecule test)
}

# main: run checks based on argument
main() {
    case "${1:-}" in
        all)
            check_molecule
            check_roles_dir
            check_roles
            check_tests
            ;;
        molecule)
            check_molecule
            ;;
        roles)
            check_roles_dir
            check_roles
            ;;
        remove)
            # remove molecule tests: optional role name in $2
            remove_molecule_tests "${2:-}"
            ;;
        tests)
            check_tests
            ;;
        create)
            create_molecule_scenario "${2:-}"
            ;;
        list)
            list_molecule_instances "${2:-}"
            ;;
        test)
            test_molecule_for_role "${2:-}"
            ;;
        *)
            if [ -n "${1:-}" ]; then
                    printf "%s\n" "${RED}[ERROR]: Unknown command '${1}'.${NC}" >&2
                fi
                echo "Usage: $0 [all|molecule|roles|tests|create|remove|list|test]" >&2
            exit 2
            ;;
    esac
}

main "$@"
