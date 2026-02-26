# Probability Threshold Memory System

## Overview

The memory system uses a probability-based threshold to determine which insights are worth capturing. This prevents memory bloat while ensuring important information is retained.

## Configuration

Set the threshold using an environment variable:

```bash
export KIRO_MEMORY_THRESHOLD=20  # Default: 20 (capture if 20%+ chance of future use)
```

### Threshold Guidelines

- **Low (10-30)**: Aggressive capture - many memories created, good for new projects
- **Medium (40-60)**: Balanced - only moderately useful insights
- **High (70-90)**: Conservative - only high-confidence insights

## Probability Categories

The agent evaluates each potential insight against these categories:

| Category | Probability | Examples |
|----------|-------------|----------|
| User stated preference/convention | 80-100% | "we always do X", "don't use Y" |
| User corrected project behavior | 70-90% | "Actually, in this project..." |
| Discovered non-obvious pattern | 50-70% | Recurring idiom, architectural pattern |
| Troubleshot undocumented issue | 50-70% | Gotcha, workaround, config quirk |
| Learned project context | 30-50% | File locations, tool choices |
| One-time task or general knowledge | 0-10% | Don't capture |

## Insight Metadata

Each insight includes a `future_usefulness` score (0-100):

```json
{
  "id": "example-insight",
  "summary": "Example insight",
  "content": "Detailed explanation...",
  "files": ["relevant/file.py"],
  "tags": ["example", "tag"],
  "created_at": "2026-02-26T10:00:00Z",
  "future_usefulness": 75
}
```

## Filtering Memories

You can filter memories by usefulness score:

```bash
# Show only high-value memories (70+)
jq '.insights[] | .[] | select(.future_usefulness >= 70)' .kiro/memory/insights.json

# Show low-value memories that might be pruned
jq '.insights[] | .[] | select(.future_usefulness < 30)' .kiro/memory/insights.json
```

## Adjusting Scores

Edit `.kiro/memory/insights.json` to adjust scores for existing memories:

```bash
# Increase score for a specific insight
jq '(.insights.conventions[] | select(.id == "example-id") | .future_usefulness) = 90' \
  .kiro/memory/insights.json > tmp.json && mv tmp.json .kiro/memory/insights.json
```

## Benefits

1. **Automatic filtering**: Agent only creates memories above threshold
2. **User control**: Adjust threshold based on project phase
3. **Memory pruning**: Identify low-value memories for cleanup
4. **Quality metrics**: Track which types of insights are most valuable
