role_name := $(word 2, $(MAKECMDGOALS))
vault_password_file := .vault

# Prefer system bash for running recipes and scripts
SHELL := $(shell which bash 2>/dev/null || echo /bin/bash)
.SILENT:
# Prevent make from printing "Entering directory ..." for recursive makes
MAKEFLAGS += --no-print-directory
.SILENT:

.PHONY: init run lint check dry-run \
	vault encrypt decrypt \
	doc-md \
	fmt fmt-check \
	molecule-test molecule-create molecule-destroy molecule-list \
	role \
	destroy-preview destroy help

# Help target: list make targets with descriptions (targets must have trailing '##' comment)
help: ## Show this help
	@echo "Usage: make <target>"
	@echo
	@awk 'BEGIN {FS = ":.*## "; printf "Available targets:\n"} /^[a-zA-Z0-9][^:]*:.*## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## 📦 Initializes the Ansible project structure in the current directory
	@$(SHELL) scripts/bash/init.sh $(vault_password_file)

role: ## 🛠️ Scaffolds a new role with Molecule, README, specs, and example vars
	@$(SHELL) scripts/bash/role.sh $(role_name) $(vault_password_file)

run: ## 🚀 Runs the site.yml playbook
	@$(SHELL) scripts/bash/run-site.sh run

dry-run: ## 🧪 Runs site.yml in check mode (no changes)
	@$(SHELL) scripts/bash/run-site.sh check

lint: ## 🧪 Lints the playbook
	@$(SHELL) scripts/bash/lint.sh

fmt: ## 🧹 Format YAML files with Prettier (via script)
	@$(SHELL) scripts/bash/fmt.sh write

fmt-check: ## 🔎 Check YAML formatting without writing changes (via script)
	@$(SHELL) scripts/bash/fmt.sh check

check: ## 🛜 Pings all hosts
	@$(SHELL) scripts/bash/check-ping.sh

vault: ## 🔐 Encrypts group_vars, host_vars, and roles defaults
	@$(SHELL) scripts/bash/vault-bulk-encrypt.sh encrypt $(vault_password_file)

encrypt: ## 🔐 Encrypts group_vars, host_vars, and roles defaults
	@$(SHELL) scripts/bash/vault-bulk-encrypt.sh encrypt $(vault_password_file)

decrypt: ## 🔓 Decrypts group_vars, host_vars, and roles defaults
	@$(SHELL) scripts/bash/vault-bulk-encrypt.sh decrypt $(vault_password_file)

doc-md: ## 📘 Generates README.md with project structure and usage
	@$(SHELL) scripts/bash/doc-md.sh

molecule-test: ## 🧪 Run molecule test for a specific role (provide role name)
	@$(SHELL) scripts/bash/molecule-checks.sh test $(role_name)

molecule-create: ## 🧪 Create molecule scenario for role (must provide role)
	@$(SHELL) scripts/bash/molecule-checks.sh create $(role_name)

molecule-destroy: ## 🧪 Remove molecule tests (role optional; interactive)
	@$(SHELL) scripts/bash/molecule-checks.sh remove $(role_name)

molecule-list: ## 🧪 List molecule instances for a role
	@$(SHELL) scripts/bash/molecule-checks.sh list $(role_name)

scaffold-inventory: ## 🧩 Scaffold `group_vars/` and `host_vars/` from inventory
	@$(SHELL) scripts/bash/scaffold_from_inventory.sh inventory/hosts.yml

bootstrap: ## 🚀 Bootstrap a new server (usage: make bootstrap host=hostname)
	@$(SHELL) scripts/bash/bootstrap.sh $(host)

destroy-preview: ## 📋 Preview what `destroy` would remove (no deletion)
	@$(SHELL) scripts/bash/destroy-preview.sh

destroy: ## ⚠️ Permanently deletes all files and directories in the current directory except safe-list
	@$(SHELL) scripts/bash/destroy.sh

%:
	@first="$(word 1,$(MAKECMDGOALS))"; \
	second="$(word 2,$(MAKECMDGOALS))"; \
	current="$@"; \
	# If the invocation was `make <cmd> <arg>` and <cmd> is one of the
	# allowed argument-taking commands, treat the second word as an argument
	# (not a target) and succeed silently for that phantom target.
	case "$$first" in \
		role|molecule-create|molecule-destroy|molecule-list) \
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
_arg_cmds := role molecule-create molecule-destroy molecule-list
ifneq (,$(filter $(_first_goal),$(_arg_cmds)))
ifneq (,$(_second_word))
$(eval $(_second_word): ; @true)
endif
endif
