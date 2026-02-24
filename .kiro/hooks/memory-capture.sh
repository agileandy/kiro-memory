#!/bin/bash

# Memory capture hook - runs at end of each agent turn
# Prompts agent to reflect and capture insights with better keyword guidance

MEMORY_FILE=".kiro/memory/insights.json"
MEMORY_PROMPT_FILE=".kiro/hooks/.memory-prompt"

# Check if memory system exists
if [[ ! -f "$MEMORY_FILE" ]]; then
    exit 0
fi

# Create a prompt for the agent to see on next interaction
cat > "$MEMORY_PROMPT_FILE" << 'EOF'

📝 MEMORY REFLECTION:
Did you learn anything new in this conversation that should be remembered?

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  CRITICAL: KEYWORD/TAG QUALITY DETERMINES RETRIEVABILITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This system uses GREP-BASED search (not semantic/AI search).
Memories are ONLY found if the exact search words appear in:
  • summary
  • content
  • tags

Example failure case:
  Memory: "Use AWS profile X for prod"
  Query: "search logs in aws"  → NOT FOUND (no "logs" word)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WHEN ADDING MEMORIES, INCLUDE ALL LIKELY SEARCH TERMS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ BAD: "Use AWS profile X for prod"
✅ GOOD: "AWS CLI commands require explicit profile specification. ALL AWS commands (logs, cloudwatch, s3, ec2, lambda) must use --profile flag. Profile X for prod, profile Y for non-prod."

Tags should include:
  • Primary topic: aws, cloud, database, api
  • Related tools: cloudwatch, s3, postgres, redis
  • Action verbs: deploy, query, search, logs
  • Antonyms/variants: prod, production, non-prod, dev, staging

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BEFORE ADDING: TEST RETRIEVABILITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Simulate how this memory would be found. Ask yourself:
  "What would I type to search for this?"

Then test it:
  rg -A 3 "your-search-term" .kiro/memory/insights.json

If it doesn't appear, add those search terms to the memory.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WHEN TO ADD MEMORY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Add to memory if you:
- Made an architecture decision
- Established a new convention
- Discovered a pattern specific to this project
- Chose one approach over another (and why)
- Encountered a gotcha or pitfall
- Learned a user preference or workflow

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HOW TO ADD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Check for duplicates: rg "similar-keyword" .kiro/memory/insights.json
2. Add insight to appropriate category in .kiro/memory/insights.json
3. Update metadata (total_insights, last_updated)

Categories:
  • conventions - Code style, naming patterns, standards
  • architecture - System design, component relationships
  • patterns     - Idioms, common approaches in this codebase
  • decisions    - Why X was chosen over Y
  • gotchas      - Common pitfalls, troubleshooting tips

EOF

# Output the prompt to stderr so agent sees it
cat "$MEMORY_PROMPT_FILE" >&2

# Clean up prompt file
rm "$MEMORY_PROMPT_FILE"

exit 0
