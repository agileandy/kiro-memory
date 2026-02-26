#!/bin/bash

# Enhanced memory capture hook - runs at end of each agent turn
# Analyzes conversation and suggests specific memories to create

MEMORY_FILE=".kiro/memory/insights.json"
THRESHOLD="${KIRO_MEMORY_THRESHOLD:-20}"

# Check if memory system exists
if [[ ! -f "$MEMORY_FILE" ]]; then
    exit 0
fi

# Read hook event from STDIN
HOOK_EVENT=$(cat)

# Output memory reflection prompt to STDERR (shown to agent)
cat >&2 << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 MEMORY CAPTURE CHECKPOINT (Threshold: ${THRESHOLD}%)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Run the probability checklist NOW:

1. ✓ User stated preference/convention? (80-100%)
2. ✓ User corrected project behavior? (70-90%)
3. ✓ Discovered non-obvious pattern? (50-70%)
4. ✓ Troubleshot undocumented issue? (50-70%)
5. ✓ Learned project context? (30-50%)
6. ✗ One-time task/general knowledge? (0-10%)

For EACH item that applies:
- Estimate probability (0-100)
- If >= ${THRESHOLD}%, CREATE the memory NOW
- Include future_usefulness score

REQUIRED: State one of:
  "✅ Created N memories (IDs: ...)"
  "⏭️  No memories above ${THRESHOLD}% threshold"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  KEYWORD QUALITY REMINDER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Grep-based search requires EXACT word matches in summary/content/tags.

❌ BAD: "Use AWS profile X"
✅ GOOD: "AWS CLI commands (logs, cloudwatch, s3, ec2, lambda) require 
         --profile flag. Profile X for prod/production, Y for dev/staging."

Test retrievability: rg -A 3 "search-term" .kiro/memory/insights.json

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF

exit 0
