# 🧰 **Ansible Scaffolding**

Minimalistic Ansible project scaffold with ergonomic Makefile automation.
Includes role generator, Molecule integration, Vault support, and auto-generated README.
Designed for clarity, reproducibility, and contributor onboarding.

---

## ⚙️ Installation

```bash
git clone https://github.com/indigo-soft/ansible-scaffolding.git
cd ansible-scaffolding
make init
```

## 🛠️ Makefile Commands
make init                     # Create files and folders
make role [role-name]         # Generate a new role [role-name]
make encrypt                  # Encrypt file using Vault with default vault-id
make decrypt                  # Decrypt file using Vault with default vault-id
make doc-md                   # Generate README.md from template
make molecule-test            # Run Molecule tests for all roles

## 🔐 Vault Integration
- Vault password stored in .vault (ignored by Git)

## 🧪 Molecule Testing
- Run make molecule-test to test all roles
- Molecule scenarios stored in molecule/
- Supports local testing and CI integration

## 📄 Auto-Documentation
- make doc-md generates README.md from template
- Template stored in docs/README.template.md
- Ensures consistent documentation across roles

## 🧼 Standards & Hygiene
- .gitignore excludes .venv/, .molecule/, *.retry, *.vault, etc.
- .gitattributes normalizes line endings and sets linguist language hints
- YAML linting and Ansible linting recommended via pre-commit (optional)

## 🧠 Philosophy
- Minimalism: No unnecessary complexity
- Reproducibility: All steps automated via Makefile
- Onboarding: New contributors can start with make role NAME=...

## 📜 License
MIT — free to use, modify, and distribute.
