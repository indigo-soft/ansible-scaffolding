#!/usr/bin/env bash
set -euo pipefail

# check_molecule: ensure molecule is installed
check_molecule() {
    command -v molecule >/dev/null 2>&1 || {
        printf "\033[31m[ERROR]: molecule not found.\033[0m\n"
        echo "Install: pip3 install --user molecule"
        exit 1
    }
}

# check_roles: ensure there are roles to test

# check_roles: ensure there are roles to test
check_roles() {
    if ! [ "$(ls -A roles 2>/dev/null)" ]; then
        printf "\033[33m[WARNING]: No roles found in ./roles. Stopping.\033[0m\n" 1>&2
        exit 1
    fi
}

# check_roles_dir: ensure the roles directory exists
check_roles_dir() {
    if ! [ -d roles ]; then
        printf "\033[33m[WARNING]: The 'roles' directory does not exist. Stopping.\033[0m\n" 1>&2
        exit 1
    fi
}

# check_tests: ensure there are molecule tests

# check_tests: ensure there are molecule tests
check_tests() {
    if ! [ -f molecule/default/verify.yml ] && ! [ -d molecule/default/tests ]; then
        printf "\033[33m[WARNING]: No Molecule tests found. Stopping.\033[0m\n" 1>&2
        exit 1
    fi
}

# create_molecule_scenario: initialize a Molecule scenario for a role
create_molecule_scenario() {
    local role_name="$1"

    if [ -z "$role_name" ]; then
        printf "\033[31m[ERROR]: Role name not provided.\033[0m\n"
        exit 1
    fi

    if [ ! -d "roles/$role_name" ]; then
        printf "\033[31m[ERROR]: Role directory roles/%s does not exist.\033[0m\n" "$role_name"
        exit 1
    fi

    cd "roles/$role_name"

    if [ -d "molecule/default" ]; then
        printf "\033[33m[INFO]: Molecule scenario already exists for role '%s'.\033[0m\n" "$role_name"
    else
        molecule init scenario default
        printf "\033[32m[INFO]: Molecule scenario initialized for role '%s'.\033[0m\n" "$role_name"
    fi
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
        tests)
            check_tests
            ;;
        create)
            create_molecule_scenario "$2"
            ;;
        *)
            echo "Usage: $0 [all|molecule|roles|tests|create]"
            exit 2
            ;;
    esac
}

main "$@"
