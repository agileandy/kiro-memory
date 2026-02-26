#!/bin/bash

# Test script for probability threshold memory system

set -e

echo "🧪 Testing Probability Threshold Memory System"
echo "=============================================="

# Setup test environment
TEST_MEMORY=".kiro/memory/test-insights.json"
cp .kiro/memory/insights.json "$TEST_MEMORY"

# Test 1: Check agent prompt includes new sections
echo ""
echo "Test 1: Verify agent prompt has probability checklist..."
if jq -r '.prompt' .kiro/agents/Default.json | grep -q "PROBABILITY CHECKLIST"; then
    echo "✅ Probability checklist found in prompt"
else
    echo "❌ Probability checklist NOT found in prompt"
    exit 1
fi

if jq -r '.prompt' .kiro/agents/Default.json | grep -q "KIRO_MEMORY_THRESHOLD"; then
    echo "✅ Memory threshold config found in prompt"
else
    echo "❌ Memory threshold config NOT found in prompt"
    exit 1
fi

if jq -r '.prompt' .kiro/agents/Default.json | grep -q "future_usefulness"; then
    echo "✅ future_usefulness field documented in prompt"
else
    echo "❌ future_usefulness field NOT documented in prompt"
    exit 1
fi

# Test 2: Verify insight format includes future_usefulness
echo ""
echo "Test 2: Verify insight format includes future_usefulness..."
INSIGHT_FORMAT=$(jq -r '.prompt' .kiro/agents/Default.json | grep -A 10 "### INSIGHT FORMAT:")
if echo "$INSIGHT_FORMAT" | grep -q '"future_usefulness": 0-100'; then
    echo "✅ future_usefulness field in insight format"
else
    echo "❌ future_usefulness field NOT in insight format"
    exit 1
fi

# Test 3: Check default threshold value
echo ""
echo "Test 3: Check KIRO_MEMORY_THRESHOLD default..."
DEFAULT_THRESHOLD="${KIRO_MEMORY_THRESHOLD:-20}"
if [ "$DEFAULT_THRESHOLD" = "20" ]; then
    echo "✅ Default threshold is 20"
else
    echo "⚠️  Custom threshold set: $DEFAULT_THRESHOLD"
fi

# Test 4: Verify probability categories are documented
echo ""
echo "Test 4: Verify probability categories..."
for category in "User stated preference" "User corrected" "Discovered non-obvious pattern" "Troubleshot undocumented" "Learned project context" "One-time task"; do
    if jq -r '.prompt' .kiro/agents/Default.json | grep -q "$category"; then
        echo "✅ Category found: $category"
    else
        echo "❌ Category NOT found: $category"
        exit 1
    fi
done

# Cleanup
rm -f "$TEST_MEMORY"

echo ""
echo "=============================================="
echo "✅ All tests passed!"
echo ""
echo "Next steps:"
echo "1. Test with actual agent interaction"
echo "2. Verify memories include future_usefulness scores"
echo "3. Test threshold filtering (set KIRO_MEMORY_THRESHOLD to different values)"
