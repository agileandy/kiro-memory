#!/bin/bash

# Test enhanced stop hook

set -e

echo "🧪 Testing Enhanced Stop Hook"
echo "=============================="

# Test 1: Hook is executable
echo ""
echo "Test 1: Verify hook is executable..."
if [ -x .kiro/hooks/memory-capture.sh ]; then
    echo "✅ Hook is executable"
else
    echo "❌ Hook is NOT executable"
    exit 1
fi

# Test 2: Hook reads KIRO_MEMORY_THRESHOLD
echo ""
echo "Test 2: Test with custom threshold..."
export KIRO_MEMORY_THRESHOLD=50
OUTPUT=$(echo '{"hook_event_name":"stop","cwd":"/test"}' | ./.kiro/hooks/memory-capture.sh 2>&1)
if echo "$OUTPUT" | grep -q "Threshold: 50%"; then
    echo "✅ Hook respects KIRO_MEMORY_THRESHOLD"
else
    echo "❌ Hook does NOT respect KIRO_MEMORY_THRESHOLD"
    echo "Output: $OUTPUT"
    exit 1
fi

# Test 3: Hook shows probability checklist
echo ""
echo "Test 3: Verify probability checklist is shown..."
if echo "$OUTPUT" | grep -q "User stated preference"; then
    echo "✅ Probability checklist shown"
else
    echo "❌ Probability checklist NOT shown"
    exit 1
fi

# Test 4: Hook shows keyword reminder
echo ""
echo "Test 4: Verify keyword quality reminder..."
if echo "$OUTPUT" | grep -q "KEYWORD QUALITY REMINDER"; then
    echo "✅ Keyword reminder shown"
else
    echo "❌ Keyword reminder NOT shown"
    exit 1
fi

# Test 5: Hook requires explicit response
echo ""
echo "Test 5: Verify required response format..."
if echo "$OUTPUT" | grep -q "REQUIRED: State one of"; then
    echo "✅ Required response format shown"
else
    echo "❌ Required response format NOT shown"
    exit 1
fi

# Test 6: Default threshold is 20
echo ""
echo "Test 6: Verify default threshold..."
unset KIRO_MEMORY_THRESHOLD
OUTPUT=$(echo '{"hook_event_name":"stop","cwd":"/test"}' | ./.kiro/hooks/memory-capture.sh 2>&1)
if echo "$OUTPUT" | grep -q "Threshold: 20%"; then
    echo "✅ Default threshold is 20%"
else
    echo "❌ Default threshold is NOT 20%"
    echo "Output: $OUTPUT"
    exit 1
fi

echo ""
echo "=============================="
echo "✅ All tests passed!"
echo ""
echo "The enhanced stop hook will now:"
echo "1. Show probability checklist at end of each turn"
echo "2. Display current threshold"
echo "3. Require explicit memory creation acknowledgment"
echo "4. Remind about keyword quality"
