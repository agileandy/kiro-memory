#!/bin/bash
# Test if a memory is retrievable with different search terms
# Usage: .kiro/memory-test.sh <memory-id> <search-terms...>

MEMORY_FILE=".kiro/memory/insights.json"

if [[ ! -f "$MEMORY_FILE" ]]; then
    echo -e "❌ Memory file not found. Run 'memory.sh init' first."
    exit 1
fi

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <memory-id> <search-term1> <search-term2> ..."
    echo ""
    echo "Example:"
    echo "  $0 aws-profile-convention aws logs cloudwatch profile"
    exit 1
fi

MEMORY_ID="$1"
shift
SEARCH_TERMS=("$@")

# Find and display the memory
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "📝 Testing Memory: $MEMORY_ID"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Extract the memory using jq
MEMORY_JSON=$(jq -r --arg id "$MEMORY_ID" '
    .insights[][] | select(.id == $id)
' "$MEMORY_FILE" 2>/dev/null)

if [[ -z "$MEMORY_JSON" ]]; then
    echo -e "❌ Memory with ID '$MEMORY_ID' not found."
    echo ""
    echo "Available memory IDs:"
    jq -r '.insights[][] | .id' "$MEMORY_FILE" | sort -u
    exit 1
fi

# Display memory details
echo -e "\033[0;36mMemory Content:\033[0m"
echo "$MEMORY_JSON" | jq -r '"  Summary: \(.summary)\n  Content: \(.content)\n  Tags: \(.tags | join(", "))"'
echo ""

# Test each search term
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "🔍 Search Term Tests"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

FOUND_COUNT=0
TOTAL_COUNT=${#SEARCH_TERMS[@]}

for term in "${SEARCH_TERMS[@]}"; do
    # Test if this term finds the memory
    # We search for the term, then check if our memory ID appears nearby
    MATCH=$(rg -i -C 20 "$term" "$MEMORY_FILE" 2>/dev/null | grep -q "\"id\": \"$MEMORY_ID\"" && echo "yes" || echo "no")

    if [[ "$MATCH" == "yes" ]]; then
        echo -e "  ✅ '$term' → FOUND"
        ((FOUND_COUNT++))
    else
        echo -e "  ❌ '$term' → NOT FOUND"
    fi
done

echo ""
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "📊 Results: $FOUND_COUNT/$TOTAL_COUNT search terms would find this memory"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $FOUND_COUNT -eq $TOTAL_COUNT ]]; then
    echo -e "\n✅ Great! All search terms work."
    exit 0
elif [[ $FOUND_COUNT -gt $((TOTAL_COUNT / 2)) ]]; then
    echo -e "\n⚠️  Some search terms missing. Consider adding them to content or tags."
    exit 0
else
    echo -e "\n❌ Most search terms fail! This memory won't be found easily."
    echo ""
    echo "Suggested fixes:"
    echo "  1. Add missing terms to the content field"
    echo "  2. Add missing terms to the tags array"
    echo "  3. Rewrite summary to include primary keywords"
    exit 1
fi
