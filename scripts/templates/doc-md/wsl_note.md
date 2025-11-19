Notes:
- For correct `chmod` behaviour on WSL, add the following to `/etc/wsl.conf` on the Windows host:

```
[automount]
options = "metadata"
```

This enables metadata (and preserves permissions) when interacting with Linux files from Windows.
Without it, `chmod` may not behave as expected.
