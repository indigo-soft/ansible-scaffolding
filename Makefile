role_name := $(word 2, $(MAKECMDGOALS))
vault_password_file := .vault

# Prefer system bash for running recipes and scripts
SHELL := $(shell which bash 2>/dev/null || echo /bin/bash)
.SILENT:
# Prevent make from printing "Entering directory ..." for recursive makes
MAKEFLAGS += --no-print-directory
.SILENT:

.PHONY: init run lint check dry-run \
	vault vault-edit encrypt decrypt \
	doc-md \
	molecule-test molecule-create molecule-destroy molecule-list \
	role \
	destroy-preview destroy help

# Help target: list make targets with descriptions (targets must have trailing '##' comment)
help: ## Show this help
	@echo "Usage: make <target>"
	@echo
	@awk 'BEGIN {FS = ":.*## "; printf "Available targets:\n"} /^[a-zA-Z0-9][^:]*:.*## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## 📦 Initializes the Ansible project structure in the current directory
	@$(SHELL) scripts/init.sh $(vault_password_file)

role: ## 🛠️ Scaffolds a new role with Molecule, README, specs, and example vars
	@$(SHELL) scripts/role.sh $(role_name) $(vault_password_file)

run: ## 🚀 Runs the site.yml playbook
	ansible-playbook -i inventory site.yml

dry-run: ## 🔍 Dry-run (check mode)
	ansible-playbook -i inventory site.yml --check

lint: ## 🧪 Lints the playbook
	@command -v ansible-lint >/dev/null 2>&1 || { \
		printf "\033[31m[WARNING]: ansible-lint not found.\033[0m\n"; \
		echo "Install: pip3 install --user ansible-lint  OR pipx install ansible-lint"; \
		echo "Ensure \"~/.local/bin\" is in your PATH if you used --user."; \
		exit 1; \
	}
	ansible-lint site.yml

check: ## 🛜 Pings all hosts
	@PY=$$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true) ; \
	if [ -n "$$PY" ]; then \
		ansible -i inventory all -m ping -e "ansible_python_interpreter=$$PY" ; \
	else \
		ansible -i inventory all -m ping ; \
	fi

vault: ## 🔐 Encrypts variables using Vault
	@test -f $(vault_password_file) || head -c 32 /dev/urandom | base64 > $(vault_password_file)
	@chmod 600 $(vault_password_file)
	ansible-vault encrypt group_vars/all.yml --vault-password-file $(vault_password_file)  --encrypt-vault-id default > /dev/null


encrypt: ## 🔐 Encrypt role files and related group_vars
	@$(SHELL) scripts/encrypt-role.sh $(role_name) $(vault_password_file)

decrypt: ## 🔓 Decrypts Vault variables
	ansible-vault decrypt group_vars/all.yml --vault-password-file $(vault_password_file)

vault-edit: ## ✏️ Edits Vault variables
	@bash -c 'EDITOR="$${VISUAL:-$${EDITOR:-$$(command -v nano 2>/dev/null || command -v vi 2>/dev/null || echo vi)}}" ; export EDITOR ; ansible-vault edit group_vars/all.yml --vault-password-file $(vault_password_file)'

doc-md: ## 📘 Generates README.md with project structure and usage
	@$(SHELL) scripts/doc-md.sh

molecule-test: ## 🧪 Run molecule test for a specific role (provide role name)
	@$(SHELL) scripts/molecule-checks.sh test $(role_name)

molecule-create: ## 🧪 Create molecule scenario for role (must provide role)
	@$(SHELL) scripts/molecule-checks.sh create $(role_name)

molecule-destroy: ## 🧪 Remove molecule tests (role optional; interactive)
	@$(SHELL) scripts/molecule-checks.sh remove $(role_name)

molecule-list: ## 🧪 List molecule instances for a role
	@$(SHELL) scripts/molecule-checks.sh list $(role_name)

destroy-preview: ## 📋 Preview what `destroy` would remove (no deletion)
	@$(SHELL) scripts/destroy-preview.sh

destroy: ## ⚠️ Permanently deletes all files and directories in the current directory except safe-list
	@$(SHELL) scripts/destroy.sh

%:
	@first="$(word 1,$(MAKECMDGOALS))"; \
	second="$(word 2,$(MAKECMDGOALS))"; \
	current="$@"; \
	# If the invocation was `make <cmd> <arg>` and <cmd> is one of the
	# allowed argument-taking commands, treat the second word as an argument
	# (not a target) and succeed silently for that phantom target.
	case "$$first" in \
		role|molecule-create|molecule-destroy|molecule-list|encrypt) \
			if [ "$$current" = "$$second" ]; then exit 0; fi; \
		;; \
	esac; \
	printf "\033[31m[ERROR]: Unknown make target '%s'.\033[0m\n" "$(MAKECMDGOALS)" >&2; \
	$(MAKE) --no-print-directory help; \
	exit 2

# If the user invoked `make <cmd> <arg>` where <cmd> is one of the commands
# that accepts an argument (role, molecule-create, molecule-destroy,
# molecule-list, encrypt), create a no-op target for the second word so
# make doesn't try to treat it as an actual target and trigger the default
# error rule. This is evaluated at parse time.
_first_goal := $(firstword $(MAKECMDGOALS))
_second_word := $(word 2,$(MAKECMDGOALS))
_arg_cmds := role molecule-create molecule-destroy molecule-list encrypt
ifneq (,$(filter $(_first_goal),$(_arg_cmds)))
ifneq (,$(_second_word))
$(eval $(_second_word): ; @true)
endif
endif
