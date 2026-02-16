# Kiro Memory System

A code-free RAG (Retrieval-Augmented Generation) memory system for AI coding agents. Gives agents persistent memory across sessions without bloating context windows.

## What It Does

AI agents lose context between sessions. They forget your conventions, architecture decisions, patterns, and gotchas.

Kiro Memory solves this by storing project insights in JSON and using targeted retrieval (via `rg`) so agents only load relevant memory.

## How It Works

```
User asks: "How should I name this Python function?"
                ↓
    Extracts search terms: python, naming, convention
                ↓
    Runs: rg -A 5 -B 1 "python" .kiro/memory/insights.json
                ↓
    Only relevant insights retrieved (e.g., "snake_case naming")
                ↓
    Agent responds using that targeted context
```

**Key insight**: The agent never reads the entire memory file. It searches for only what's relevant.

## Quick Start

1. Copy `.kiro` directory to your project:
   ```bash
   cp -r /path/to/memory-system/.kiro /your/project/
   ```

2. Initialize memory:
   ```bash
   cd /your/project
   .kiro/memory.sh init
   ```

3. Add an insight:
   ```bash
   .kiro/memory.sh add
   ```

## Memory Categories

- **conventions** - Code style, naming patterns, team standards
- **architecture** - System design, component relationships
- **patterns** - Idioms, common approaches in this codebase
- **decisions** - Why X was chosen over Y
- **gotchas** - Common pitfalls, troubleshooting tips

## CLI Commands

```bash
.kiro/memory.sh init      # Initialize memory for project
.kiro/memory.sh status    # Show memory statistics
.kiro/memory.sh show      # Display all insights
.kiro/memory.sh search    # Search by keyword or tag
.kiro/memory.sh add       # Manually add a new insight
.kiro/memory.sh clear     # Clear all memory (requires confirmation)
```

## Insight Format

Each insight in `.kiro/memory/insights.json`:

```json
{
  "id": "short-kebab-case",
  "summary": "One-line summary",
  "content": "Full explanation (2-4 sentences)",
  "files": ["related", "files"],
  "tags": ["relevant", "tags"],
  "created_at": "ISO-8601-timestamp"
}
```

### Understanding "Related Files"

When you add a "related file" reference to an insight, the memory system stores that reference but **does not modify the original file**. The reference helps you:

- Find which files are related to which insights
- Navigate from an insight to relevant source files
- Track connections between code and decisions

**Example**: If you add an insight about "snake_case naming" and reference `AGENTS.md`, the memory stores that connection for future reference but doesn't change `AGENTS.md` itself.

## Agent Integration

Agents configured with the memory-capture hook will automatically:
1. Check memory before responding (using `rg` to find relevant insights)
2. Prompt to add new insights after each interaction
3. Maintain memory across sessions

See `.kiro/agents/Default.json` for example configuration.

## Why This Approach?

See [why-memory.md](why-memory.md) for a detailed comparison of this approach vs. context stuffing.

**TL;DR**: Context stuffing dumps 10,000+ tokens of irrelevant information. Kiro Memory retrieves 50-500 tokens of exactly what's needed.

## Git Integration

**Team-shared memory** (commit to git):
```bash
git add .kiro/memory/insights.json
git commit -m "Update project memory"
```

**Local-only memory** (add to .gitignore):
```bash
echo ".kiro/memory/insights.json" >> .gitignore
```

## Requirements

Before using the Kiro Memory System, ensure you have:

### Prerequisites

- **jq 1.6+** - for JSON manipulation
- **rg (ripgrep)** - for fast search

### Check Versions

```bash
jq --version   # should be 1.6 or higher
rg --version   # ripgrep should be installed
```

### Installation

**macOS (Homebrew):**
```bash
brew install jq ripgrep
```

**Ubuntu/Debian:**
```bash
sudo apt-get install jq ripgrep
# Note: Ubuntu 18.04 ships with jq 1.5. You may need jq 1.6+ from backports or manual install.
```

**From source (if needed):**
- jq: https://stedolan.github.io/jq/download/
- ripgrep: https://github.com/BurntSushi/ripgrep#installation

## License

Part of the Kiro Immersion training materials.
