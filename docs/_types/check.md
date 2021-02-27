---
name: check
---
Runs a given command. OK if returns 0, FAILED otherwise.

### Syntax

```bash
check evalstr
```

### Example

```bash
check "[ -d $HOME/.ssh/id_rsa ]"'
if check_failed; then ...'
```