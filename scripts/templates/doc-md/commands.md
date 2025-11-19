## 🚀 Commands

```bash
make init                    # initialize project structure
make run                     # run site.yml
make lint                    # lint playbook (requires ansible-lint)
make check                   # ping hosts
make dry-run                 # run in check mode
make vault                   # encrypt variables
make decrypt                 # decrypt variables
make vault-edit              # edit encrypted variables
make doc-md                  # generate README.md
make role [role-name]        # scaffold new role [role-name]
make molecule-test           # full Molecule test
make molecule-verify         # verify only
make molecule-create         # create test instance
make molecule-converge       # apply role
make molecule-destroy        # destroy test instance
make molecule-idempotence    # check idempotence
make molecule-list           # list Molecule scenarios
make destroy-preview         # preview destroy (no deletion)
make destroy                 # permanently delete files in current directory (use with caution)
```
