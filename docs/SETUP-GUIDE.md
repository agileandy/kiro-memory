# Setup Guide: Protecting Your Insights from Repo Updates

## The Problem

When you pull updates from the memory-system repo, you don't want your personal insights to be overwritten.

## The Solution

The system uses **config-based memory file selection** with gitignore protection:

1. **Sample insights** are tracked in git (`sample-insights.json`)
2. **Your insights** are gitignored (`insights.json` or your custom name)
3. **Config file** specifies which file to use

---

## Quick Setup

### 1. Initialize Your Memory

```bash
./.kiro/memory.sh init
```

This creates `.kiro/memory/insights.json` (gitignored - safe from updates).

### 2. (Optional) Import Samples

```bash
./.kiro/memory.sh import-samples
```

This copies sample insights to your file for learning/testing.

### 3. Start Using

```bash
./.kiro/memory.sh add      # Add your own insights
./.kiro/memory.sh list     # View all insights
./.kiro/memory.sh remove <id>  # Remove samples you don't need
```

---

## How It Works

### File Structure

```
.kiro/memory/
├── sample-insights.json    # Tracked in git (examples)
└── insights.json           # Gitignored (your data)
```

### Configuration

`.kiro/settings/config.json`:
```json
{
  "default_agent": ".kiro/agents/Default.json",
  "memory_file": ".kiro/memory/insights.json"
}
```

The `memory_file` setting tells the system which file to use.

### What's Protected

✅ **Your insights file** (`.kiro/memory/insights.json`)
- Listed in `.gitignore`
- Never tracked by git
- Never overwritten on pull
- Completely under your control

✅ **Your config** (`.kiro/settings/config.json`)
- You can customize the memory file name
- Safe to commit or gitignore

❌ **Sample insights** (`.kiro/memory/sample-insights.json`)
- Tracked in git (for reference)
- May be updated when you pull
- Not used unless you import them

---

## Custom Memory File Names

Want to use a different name? Edit `.kiro/settings/config.json`:

```json
{
  "memory_file": ".kiro/memory/my-project-insights.json"
}
```

Then initialize:
```bash
./.kiro/memory.sh init
```

**Benefits:**
- Project-specific names
- Multiple memory files for different contexts
- Clear separation from repo samples

---

## Workflow: After Pulling Updates

```bash
# 1. Pull latest changes
git pull

# 2. Your insights are untouched (gitignored)
./.kiro/memory.sh status
# Shows your existing insights

# 3. (Optional) Check if new samples were added
./.kiro/memory.sh help
# Shows: Current memory file: .kiro/memory/insights.json

# 4. (Optional) Import new samples if desired
./.kiro/memory.sh import-samples
# Merges any new samples into your file
```

---

## Verification

Check that your insights file is gitignored:

```bash
git status .kiro/memory/insights.json
```

**Expected output:**
```
fatal: pathspec '.kiro/memory/insights.json' did not match any files
```

This means it's gitignored (protected).

---

## Migration from Old Setup

If you have an existing `insights.json` that was tracked:

```bash
# 1. Backup your current insights
cp .kiro/memory/insights.json .kiro/memory/my-backup.json

# 2. Remove from git tracking
git rm --cached .kiro/memory/insights.json

# 3. Verify it's now gitignored
git status .kiro/memory/insights.json

# 4. Commit the removal
git commit -m "Untrack insights.json (now gitignored)"

# 5. Your file still exists locally and is now protected
./.kiro/memory.sh status
```

---

## FAQ

**Q: What if I want to share my insights with the team?**

A: You have options:
1. Commit your custom-named file: `git add .kiro/memory/team-insights.json`
2. Export specific insights and share them
3. Use a different config for team vs personal insights

**Q: Can I have multiple memory files?**

A: Yes! Change `memory_file` in config.json to switch between them.

**Q: What happens to sample-insights.json when I pull?**

A: It may be updated with new examples, but your `insights.json` is unaffected.

**Q: How do I know which file I'm using?**

A: Run `./.kiro/memory.sh help` - it shows "Current memory file: ..." at the bottom.

---

## Summary

✅ **Your insights are safe** - gitignored by default
✅ **Samples are separate** - tracked for reference only  
✅ **Config-based** - you control which file to use
✅ **Pull-safe** - updates never touch your data
✅ **Flexible** - use custom names if desired
