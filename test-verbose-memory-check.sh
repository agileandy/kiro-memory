#!/bin/bash

# Test verbose memory check feature

set -e

echo "🧪 Testing Verbose Memory Check"
echo "================================"

# Test 1: Verify prompt includes memory check format
echo ""
echo "Test 1: Verify memory check format in prompt..."
if jq -r '.prompt' .kiro/agents/Default.json | grep -q "💭 Memory check:"; then
    echo "✅ Memory check format found in prompt"
else
    echo "❌ Memory check format NOT found in prompt"
    exit 1
fi

# Test 2: Verify examples are provided
echo ""
echo "Test 2: Verify memory check examples..."
EXAMPLES=(
    "One-time task"
    "User stated convention"
    "General knowledge"
    "Troubleshot config issue"
)

for example in "${EXAMPLES[@]}"; do
    if jq -r '.prompt' .kiro/agents/Default.json | grep -q "$example"; then
        echo "✅ Example found: $example"
    else
        echo "❌ Example NOT found: $example"
        exit 1
    fi
done

# Test 3: Verify verbose mode instructions updated
echo ""
echo "Test 3: Verify verbose mode instructions..."
if jq -r '.prompt' .kiro/agents/Default.json | grep -q "At end of EVERY response"; then
    echo "✅ Instructions specify 'every response'"
else
    echo "❌ Instructions don't specify 'every response'"
    exit 1
fi

# Test 4: Verify future_usefulness mentioned in verbose output
echo ""
echo "Test 4: Verify future_usefulness in verbose output..."
if jq -r '.prompt' .kiro/agents/Default.json | grep -q "future_usefulness"; then
    echo "✅ future_usefulness included in verbose output"
else
    echo "❌ future_usefulness NOT included in verbose output"
    exit 1
fi

# Test 5: Check KIRO_MEMORY_VERBOSE default
echo ""
echo "Test 5: Check KIRO_MEMORY_VERBOSE default..."
VERBOSE="${KIRO_MEMORY_VERBOSE:-true}"
if [ "$VERBOSE" = "true" ]; then
    echo "✅ Default verbose mode is true"
else
    echo "⚠️  Custom verbose mode: $VERBOSE"
fi

echo ""
echo "================================"
echo "✅ All tests passed!"
echo ""
echo "In verbose mode, agent will now show:"
echo "  💭 Memory check: [reason with probability if applicable]"
echo ""
echo "This provides transparency about memory decisions without"
echo "requiring explicit user interaction."
