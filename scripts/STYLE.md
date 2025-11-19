Bash script style guide for this repository
==========================================

Convention (required):

- Write Bash scripts as a set of small functions.
- Before each function, add a short comment line describing the function (this makes scanning files easier).
- Use `set -euo pipefail` at the top of scripts.
- Use `find -print0` and `read -d ''` or `xargs -0` for null-safe file lists.
- When doing placeholder substitution, prefer `sed "s|OLD|NEW|g"` to avoid `/` escaping issues.

Example layout:

```bash
#!/usr/bin/env bash
set -euo pipefail

# print_error: print an error message and exit
print_error() {
  printf "%s\n" "ERROR: $1" >&2
  exit ${2:-1}
}

# do_work: main worker that performs the task
do_work() {
  # ...
}

main() {
  do_work "$@"
}

main "$@"
```

Rationale:

- Functions improve readability, allow local scoping, and make testing easier.
- A short comment before each function visually separates code blocks and documents intent.

If you want to change this policy, propose it in the repository README or open a PR.
