role_name := $(word 2, $(MAKECMDGOALS))
vault_password_file := .vault

# Prefer system bash for running recipes and scripts
SHELL := $(shell which bash 2>/dev/null || echo /bin/bash)
.SILENT:

.PHONY: init run lint check dry-run vault decrypt vault-edit doc-md \
	molecule-test molecule-verify molecule-coverage molecule-create \
	molecule-converge molecule-destroy molecule-idempotence molecule-list \
	role destroy-preview destroy

## 📦 Initializes the Ansible project structure in the current directory
init:
	@$(SHELL) scripts/init.sh $(vault_password_file)

## 🚀 Runs the site.yml playbook
run:
	ansible-playbook -i inventory site.yml

## 🔍 Dry-run (check mode)
dry-run:
	ansible-playbook -i inventory site.yml --check

## 🧪 Lints the playbook
lint:
	@command -v ansible-lint >/dev/null 2>&1 || { \
		printf "\033[31m[WARNING]: ansible-lint not found.\033[0m\n"; \
		echo "Install: pip3 install --user ansible-lint  OR pipx install ansible-lint"; \
		echo "Ensure \"~/.local/bin\" is in your PATH if you used --user."; \
		exit 1; \
	}
	ansible-lint site.yml

## 🛜 Pings all hosts
check:
	@PY=$$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true) ; \
	if [ -n "$$PY" ]; then \
		ansible -i inventory all -m ping -e "ansible_python_interpreter=$$PY" ; \
	else \
		ansible -i inventory all -m ping ; \
	fi

## 🔐 Encrypts variables using Vault
vault:
	@test -f $(vault_password_file) || head -c 32 /dev/urandom | base64 > $(vault_password_file)
	@chmod 600 $(vault_password_file)
	ansible-vault encrypt group_vars/all.yml --vault-password-file $(vault_password_file)  --encrypt-vault-id default > /dev/null


## 🔐 Encrypt role files and related group_vars
encrypt:
	@$(SHELL) scripts/encrypt-role.sh $(role_name) $(vault_password_file)

## 🔓 Decrypts Vault variables
decrypt:
	ansible-vault decrypt group_vars/all.yml --vault-password-file $(vault_password_file)

## ✏️ Edits Vault variables
vault-edit:
	@bash -c 'EDITOR="$${VISUAL:-$${EDITOR:-$$(command -v nano 2>/dev/null || command -v vi 2>/dev/null || echo vi)}}" ; export EDITOR ; ansible-vault edit group_vars/all.yml --vault-password-file $(vault_password_file)'

## 📘 Generates README.md with project structure and usage
doc-md:
	@$(SHELL) scripts/doc-md.sh

## 🧪 Molecule commands
molecule-test:
	@$(SHELL) scripts/molecule-checks.sh all && molecule test

molecule-create:
	@$(SHELL) scripts/molecule-checks.sh create $(role_name)

molecule-list:
	@$(SHELL) scripts/molecule-checks.sh molecule && $(SHELL) scripts/molecule-checks.sh roles && test -f roles/$(role_name)/molecule/default/molecule.yml && cd roles/$(role_name) && molecule list || { echo "\033[31m[ERROR]: molecule.yml not found in roles/$(role_name)/molecule/default/.\033[0m"; exit 1; }

## 🛠️ Scaffolds a new role with Molecule, README, specs, and example vars
role:
	@$(SHELL) scripts/role.sh $(role_name) $(vault_password_file)

## 📋 Preview what `destroy` would remove (no deletion)
destroy-preview:
	@$(SHELL) scripts/destroy-preview.sh

## ⚠️ Permanently deletes all files and directories in the current directory except safe-list
destroy:
	@$(SHELL) scripts/destroy.sh

%:
	@:
