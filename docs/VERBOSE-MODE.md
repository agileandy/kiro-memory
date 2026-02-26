# Verbose Mode & Memory Check

## Verbose Mode

**Default:** ON (shows memory activity and reasoning)

### Configuration

```bash
export KIRO_MEMORY_VERBOSE=true   # Default: show memory activity
export KIRO_MEMORY_VERBOSE=false  # Silent mode
```

### Verbose Mode Features

When enabled, the agent provides:

**1. Memory Creation Summary**
Shows details when memories are created:
- ID
- Category  
- Summary
- Tags
- Future usefulness score

**2. Memory Check Statement**
At the end of EVERY response:
```
💭 Memory check: [reason]
```

Examples:
- `💭 Memory check: One-time task (renamed files), no memory needed`
- `💭 Memory check: User stated convention (85%), created memory 'lowercase-filenames'`
- `💭 Memory check: General knowledge about hooks, already documented`
- `💭 Memory check: Troubleshot config issue (70%), created memory 'hook-permissions'`

### Silent Mode

When `KIRO_MEMORY_VERBOSE=false`:
- No memory creation announcements
- No memory check statements
- Memories still created based on threshold
- Cleaner output for automation

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

## When to Use Each Mode

✅ **Use verbose mode when:**
- Working interactively
- Want to understand memory decisions
- Learning the system
- Debugging memory creation
- Want transparency into probability scoring

✅ **Use silent mode when:**
- Running automated scripts
- Batch operations
- Cleaner output needed
- Integrating with other tools

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
