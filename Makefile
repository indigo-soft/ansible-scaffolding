role_name := $(firstword $(MAKECMDGOALS))

.PHONY: init run lint check dry-run vault decrypt vault-edit doc-md \
        molecule-test molecule-verify molecule-coverage molecule-create \
        molecule-converge molecule-destroy molecule-idempotence molecule-list \
        role

## 📦 Initializes the Ansible project structure in the current directory
init:
	@mkdir -p inventory group_vars host_vars playbooks files templates roles
	@echo "[defaults]\ninventory = ./inventory\nroles_path = ./roles\nvault_password_file = .vault_pass.txt\n" > ansible.cfg
	@echo "- name: Site playbook\n  hosts: all\n  gather_facts: false\n  tasks: []\n" > site.yml
	@echo "[all]\nlocalhost ansible_connection=local\n" > inventory/hosts.ini
	@echo "---\nexample_variable: value\n" > group_vars/all.yml
	@echo "collections:\n  - name: ansible.posix\n  - name: community.general\n" > requirements.yml
	@echo ".venv/\n__pycache__/\n*.retry\n*.log\n*.swp\n.vault_pass.txt\n" > .gitignore
	@echo "root = true\n\n[*]\ncharset = utf-8\nend_of_line = lf\ninsert_final_newline = true\ntrim_trailing_whitespace = true\n" > .editorconfig
	@ansible-galaxy collection install -r requirements.yml
	@echo "✅ Project structure created"

## 🚀 Runs the site.yml playbook
run:
	ansible-playbook -i inventory site.yml

## 🔍 Dry-run (check mode)
dry-run:
	ansible-playbook -i inventory site.yml --check

## 🧪 Lints the playbook
lint:
	ansible-lint site.yml

## 🛜 Pings all hosts
check:
	ansible -i inventory all -m ping

## 🔐 Encrypts variables using Vault
vault:
	@test -f .vault_pass.txt || head -c 32 /dev/urandom | base64 > .vault_pass.txt
	ansible-vault encrypt group_vars/all.yml --vault-password-file .vault_pass.txt

## 🔓 Decrypts Vault variables
decrypt:
	ansible-vault decrypt group_vars/all.yml --vault-password-file .vault_pass.txt

## ✏️ Edits Vault variables
vault-edit:
	ansible-vault edit group_vars/all.yml --vault-password-file .vault_pass.txt

## 📘 Generates README.md with project structure and usage
doc-md:
	@command -v tree >/dev/null 2>&1 || { echo '❌ Please install tree: sudo apt install tree'; exit 1; }
	@echo "# Ansible Project" > README.md
	@echo "\n## 🚀 Commands\n" >> README.md
	@echo '```bash' >> README.md
	@echo "make init                    # initialize project structure" >> README.md
	@echo "make run                     # run site.yml" >> README.md
	@echo "make lint                    # lint playbook" >> README.md
	@echo "make check                   # ping hosts" >> README.md
	@echo "make dry-run                 # run in check mode" >> README.md
	@echo "make vault                   # encrypt variables" >> README.md
	@echo "make decrypt                 # decrypt variables" >> README.md
	@echo "make vault-edit              # edit encrypted variables" >> README.md
	@echo "make doc-md                  # generate README.md" >> README.md
	@echo "make role myrole             # scaffold new role myrole}" >> README.md
	@echo "make molecule-test           # full Molecule test" >> README.md
	@echo "make molecule-verify         # verify only" >> README.md
	@echo "make molecule-create         # create test instance" >> README.md
	@echo "make molecule-converge       # apply role" >> README.md
	@echo "make molecule-destroy        # destroy test instance" >> README.md
	@echo "make molecule-idempotence    # check idempotence" >> README.md
	@echo "make molecule-list           # list Molecule scenarios" >> README.md
	@echo '```' >> README.md
	@echo "✅ README.md updated"

## 🧪 Molecule commands
molecule-test: molecule test
molecule-verify: molecule verify
molecule-coverage: molecule verify && { test -f coverage.xml && echo "✅ Coverage generated"; } || echo "ℹ️ coverage.xml not found"
molecule-create: molecule create
molecule-converge: molecule converge
molecule-destroy: molecule destroy
molecule-idempotence: molecule idempotence
molecule-list: molecule list

## 🛠️ Scaffolds a new role with Molecule, README, specs, and example vars
role:
	@test -n "$(role_name)" || { echo "❌ Please specify role name: make role myrole"; exit 1; }
	@mkdir -p roles/$(role_name)/{defaults,tasks,handlers,meta,templates,files,molecule/default}
	@echo "---\n# Default variables\n" > roles/$(role_name)/defaults/main.yml
	@echo "---\nmyrole_enabled: true\nmyrole_port: 8080\nmyrole_config_path: /etc/$(role_name)/config.yml\n" > roles/$(role_name)/defaults/main.example.yml
	@echo "---\n# Main tasks\n" > roles/$(role_name)/tasks/main.yml
	@echo "---\n# Handlers\n" > roles/$(role_name)/handlers/main.yml
	@echo "---\ndependencies: []\n" > roles/$(role_name)/meta/main.yml
	@echo "argument_specs:\n  main:\n    short_description: \"Role $(role_name) configuration\"\n    options:\n      myrole_enabled:\n        type: bool\n        default: true\n        description: \"Enable the role\"\n      myrole_port:\n        type: int\n        default: 8080\n        description: \"Service port\"\n      myrole_config_path:\n        type: str\n        default: \"/etc/$(role_name)/config.yml\"\n        description: \"Path to config file\"\n" > roles/$(role_name)/meta/argument_specs.yml
	@echo "# Config for {{ inventory_hostname }}\nenabled = {{ myrole_enabled }}\nport = {{ myrole_port }}\nconfig_path = {{ myrole_config_path }}\n" > roles/$(role_name)/templates/config.example.j2
	@echo "- name: Apply role\n  hosts: all\n  roles:\n    - $(role_name)\n" > roles/$(role_name)/molecule/default/converge.yml
	@echo "- name: Verify role\n  hosts: all\n  gather_facts: false\n  tasks:\n    - name: Confirm role applied\n      debug:\n        msg: 'Role $(role_name) applied'\n" > roles/$(role_name)/molecule/default/verify.yml
	@echo "dependency:\n  name: galaxy\ndriver:\n  name: docker\nplatforms:\n  - name: instance\n    image: ubuntu:latest\nprovisioner:\n  name: ansible\n  playbooks:\n    converge: converge.yml\n    verify: verify.yml\nscenario:\n  name: default\n" > roles/$(role_name)/molecule/default/molecule.yml
	@echo "# Role $(role_name)\n\n## 🔧 Variables\nSee [defaults/main.example.yml](defaults/main.example.yml)\n\n## 🚀 Usage\n```yaml\n- hosts: all\n  roles:\n    - $(role_name)\n```" > roles/$(role_name)/README.md
	@echo "molecule-test:\n\tmolecule test\nmolecule-verify:\n\tmolecule verify\nmolecule-create:\n\tmolecule create\nmolecule-converge:\n\tmolecule converge\nmolecule-destroy:\n\tmolecule destroy\nmolecule-idempotence:\n\tmolecule idempotence\nmolecule-list:\n\tmolecule list\n" > roles/$(role_name)/Makefile
	@mkdir -p group_vars
	@echo "---\nmyrole_enabled: true\nmyrole_port: 8080\nmyrole_config_path: /etc/$(role_name)/config.yml\n" > group_vars/webservers.yml
	@echo "✅ Role $(role_name) scaffolded"

%:
	@:
