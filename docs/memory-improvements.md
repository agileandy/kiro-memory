# Memory System Improvements Summary

## Overview

Three major improvements to make memory creation more consistent and transparent:

1. **Probability Threshold System** - Structured decision-making
2. **Enhanced Stop Hook** - Assertive prompts at end of each turn
3. **Verbose Memory Check** - Transparent reasoning

## 1. Probability Threshold System

### What It Does
Provides a structured checklist to evaluate whether insights should be captured, with probability scores (0-100%).

### Configuration
```bash
export KIRO_MEMORY_THRESHOLD=20  # Default: capture if 20%+ chance of future use
```

### Probability Categories
| Category | Score | Examples |
|----------|-------|----------|
| User stated preference/convention | 80-100% | "we always do X", "don't use Y" |
| User corrected project behavior | 70-90% | "Actually, in this project..." |
| Discovered non-obvious pattern | 50-70% | Recurring idiom, architectural pattern |
| Troubleshot undocumented issue | 50-70% | Gotcha, workaround, config quirk |
| Learned project context | 30-50% | File locations, tool choices |
| One-time task or general knowledge | 0-10% | Don't capture |

### New Insight Field
```json
{
  "id": "example",
  "summary": "...",
  "content": "...",
  "files": [],
  "tags": [],
  "created_at": "2026-02-26T10:00:00Z",
  "future_usefulness": 75
}
```

### Benefits
- Automatic filtering based on threshold
- User control via environment variable
- Ability to prune low-value memories
- Quality metrics for insights

### Documentation
- `docs/probability-threshold.md`
- Test: `test-probability-threshold.sh`

---

## 2. Enhanced Stop Hook

### What It Does
Shows assertive memory capture prompt at the end of each agent turn, requiring explicit acknowledgment.

### What You See
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 MEMORY CAPTURE CHECKPOINT (Threshold: 20%)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Run the probability checklist NOW:

1. ✓ User stated preference/convention? (80-100%)
2. ✓ User corrected project behavior? (70-90%)
3. ✓ Discovered non-obvious pattern? (50-70%)
4. ✓ Troubleshot undocumented issue? (50-70%)
5. ✓ Learned project context? (30-50%)
6. ✗ One-time task/general knowledge? (0-10%)

REQUIRED: State one of:
  "✅ Created N memories (IDs: ...)"
  "⏭️  No memories above 20% threshold"
```

### Benefits
- Forces agent to evaluate every turn
- Shows current threshold
- Includes keyword quality reminder
- Requires explicit response

### Test
- `test-enhanced-stop-hook.sh`

---

## 3. Verbose Memory Check

### What It Does
In verbose mode (default), agent shows brief reasoning about memory decisions at end of every response.

### Format
```
💭 Memory check: [reason]
```

### Examples
- `💭 Memory check: One-time task (renamed files), no memory needed`
- `💭 Memory check: User stated convention (85%), created memory 'lowercase-filenames'`
- `💭 Memory check: General knowledge about hooks, already documented`
- `💭 Memory check: Troubleshot config issue (70%), created memory 'hook-permissions'`

### Configuration
```bash
export KIRO_MEMORY_VERBOSE=true   # Default: show memory check
export KIRO_MEMORY_VERBOSE=false  # Silent mode
```

### Benefits
- Transparency without user interaction
- Learn what agent considers memorable
- Catch missed memories
- Understand probability scoring

### Documentation
- `docs/verbose-mode.md`
- Test: `test-verbose-memory-check.sh`

---

## Combined Impact

These three improvements work together:

1. **Probability Threshold** provides structured evaluation criteria
2. **Enhanced Stop Hook** forces agent to run the checklist
3. **Verbose Memory Check** shows the reasoning transparently

Result: More consistent, transparent, and controllable memory creation.

---

## Testing

All features include comprehensive test suites:

```bash
# Test all features
./test-probability-threshold.sh
./test-enhanced-stop-hook.sh
./test-verbose-memory-check.sh
```

---

## Configuration Summary

```bash
# Memory threshold (default: 20)
export KIRO_MEMORY_THRESHOLD=20

# Verbose mode (default: true)
export KIRO_MEMORY_VERBOSE=true
```

---

## Migration

Existing insights have been backfilled with `future_usefulness` scores:
- Conventions: 75
- Architecture: 70
- Patterns: 65
- Decisions: 60
- Gotchas: 80

You can adjust these scores by editing `.kiro/memory/insights.json`.

---

## Next Steps

1. Use the system and observe memory check statements
2. Adjust `KIRO_MEMORY_THRESHOLD` based on your needs
3. Review and prune low-value memories using `future_usefulness` scores
4. Provide feedback on probability categories
