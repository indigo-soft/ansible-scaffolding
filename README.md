# 🧰 Ansible Scaffolding

Minimalist Ansible project template with ergonomic Makefile automation. Includes role generator (`make role [rolename]`), Molecule integration, Vault support, and auto-generated README. Designed for clarity, repeatability, and smooth onboarding.

## 📦 Project Structure

- `Makefile` — main automation interface
- Roles live in `roles/`, created via `make role [rolename]`

## 🚀 Makefile Commands

**🔧 Initialization**
```bash
make init
```

## ▶️ Execution
```bash
make run
make dry-run
make check
```

## 🧪 Testing
```bash
make lint
make molecule-test
make molecule-verify
make molecule-idempotence
```

## 🔐 Vault
```bash
make vault
make decrypt
make vault-edit
```

## 🏗️ Role Generation
```bash
make role [rolename]
```

## 📄 Documentation
```bash
make doc-md
```

## 🧪 Molecule Commands
```bash
make molecule-create
make molecule-converge
make molecule-destroy
make molecule-list
```

## 🛠️ Requirements
- Ubuntu Server LTS (recommended)
- Ansible ≥ 2.14
- Molecule + Testinfra
- Collections: ansible.posix, community.general


## 🧬 Philosophy
- Minimal boilerplate, maximum automation
- Ergonomic, grouped command naming
- Auto-generated README
- Roles include examples (main.example.yml, config.example.j2)
- No vars/ — only defaults/ and tasks/


## 📚 License
MIT — free to use, modify, and distribute with attribution.
