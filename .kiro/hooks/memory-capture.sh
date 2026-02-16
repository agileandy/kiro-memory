#!/bin/bash

# Memory capture hook - runs at end of each agent turn
# Prompts agent to reflect and capture insights

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

Consider adding to memory if you:
- Made an architecture decision
- Established a new convention
- Discovered a pattern specific to this project
- Chose one approach over another (and why)
- Encountered a gotcha or pitfall

To add to memory:
1. Check for duplicates: rg "similar-keyword" .kiro/memory/insights.json
2. Add insight to appropriate category in .kiro/memory/insights.json
3. Update metadata (total_insights, last_updated)

Categories: conventions, architecture, patterns, decisions, gotchas

EOF

# Output the prompt to stderr so agent sees it
cat "$MEMORY_PROMPT_FILE" >&2

# Clean up prompt file
rm "$MEMORY_PROMPT_FILE"

exit 0
