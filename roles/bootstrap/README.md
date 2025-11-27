# Bootstrap Role

## Purpose

This role performs the initial setup of a new server.
It prepares the system for further configuration and deployment by:

- Creating a non-root user (default: `deploy`)
- Adding an SSH public key for secure access
- Changing the SSH port (default: `2222`)
- Disabling root login

## Variables

The role uses the following variables (defined in `group_vars/all.yml`):

- `ansible_user` — name of the deployment user (default: `deploy`)
- `ansible_pubkey` — path to the public key file (default: `files/id_rsa.pub`)
- `ssh_port` — new SSH port (default: `2222`)

## Handlers

- `Restart ssh` — restarts the SSH service after configuration changes.

## Files

- `files/id_rsa.pub` — the public key that will be added to the new user.

## Usage

Include the role in a playbook:

```yaml
- hosts: newserver
  become: true
  roles:
      - bootstrap
```
