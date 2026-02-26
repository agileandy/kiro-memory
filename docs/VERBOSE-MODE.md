# Verbose Mode & Auto-Increment Quick Reference

## Verbose Mode

**Default:** ON (shows summary after adding)

### Turn OFF (silent mode)
```bash
export KIRO_MEMORY_VERBOSE=false
```

### Turn ON
```bash
export KIRO_MEMORY_VERBOSE=true
```

### One-time silent
```bash
KIRO_MEMORY_VERBOSE=false ./.kiro/memory.sh add
```

---

## Auto-Increment Behavior

When you add an insight with a duplicate summary:

**Old behavior:** ❌ Error - rejected
**New behavior:** ✅ Auto-saves with counter suffix

### Example

```bash
# Add first insight
Summary: "Python naming convention"
→ Saved as: python-naming-convention

# Add second with same summary
Summary: "Python naming convention"
→ Note: ID adjusted to 'python-naming-convention-2' to avoid duplicate
→ Saved as: python-naming-convention-2

# Add third
→ Saved as: python-naming-convention-3
```

**Result:** All insights are saved, none are lost!

---

## When to Use Silent Mode

✅ **Use silent mode when:**
- Running automated scripts
- Batch adding many insights
- You don't need confirmation feedback
- Integrating with other tools

✅ **Use verbose mode when:**
- Adding insights manually
- You want to verify what was created
- Learning the system
- Debugging memory creation

---

## Quick Test

```bash
# Test verbose (default)
echo -e "1\nTest insight\nTest content\n\ntest" | ./.kiro/memory.sh add

# Test silent
KIRO_MEMORY_VERBOSE=false bash -c 'echo -e "1\nTest insight 2\nTest content\n\ntest" | ./.kiro/memory.sh add'

# Verify both were added
./.kiro/memory.sh list conventions | grep "test-insight"
```
