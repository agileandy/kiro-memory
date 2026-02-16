# Kiro Memory System

> **Code-free RAG (Retrieval-Augmented Generation)** memory for AI coding agents. Persistent memory across sessions without bloating context windows.

---

## The Problem: Context Stuffing

Most AI coding agents lose context between sessions. They forget your conventions, architecture decisions, patterns, and gotchas.

The naive solution is **"context stuffing"** - dumping all project knowledge into the system prompt:

```python
# This fails because:
system_prompt = """
- 200 lines of coding standards     # 95% irrelevant to any given task
- 150 lines of architecture         # Agent must filter through noise
- 100 lines of gotchas              # Quality degrades with token bloat
- 500 lines of project history      # Every session starts from scratch
"""
```

**Why this fails:**
- 10,000+ tokens of context that's mostly irrelevant
- No persistence between sessions
- No version control for evolving conventions
- Can't share knowledge across a team

---

## The Solution: Kiro Memory

Instead of dumping everything, **retrieve only what's relevant**:

```
User asks: "How should I name this Python function?"
                ↓
    Extract search terms: python, naming, convention
                ↓
    Runs: rg -A 5 -B 1 "python" .kiro/memory/insights.json
                ↓
    Only relevant insights retrieved (e.g., "snake_case naming")
                ↓
    Agent responds using that targeted context
```

**Key insight**: The agent never reads the entire memory file. It searches for only what's relevant.

### Comparison

| Aspect | Context Stuffing | Kiro Memory |
|--------|------------------|-------------|
| Tokens per query | 5,000-15,000 | 50-500 |
| Cross-session memory | None | Full |
| Team sharing | Manual | Automatic |
| Version control | None | Git-tracked |
| Relevance | 5-20% | 95-100% |

---

## Installation

### Step 1: Install Prerequisites

You need two tools:
- **jq 1.6+** - for JSON manipulation
- **rg (ripgrep)** - for fast search

#### Check if already installed:
```bash
jq --version   # should be 1.6 or higher
rg --version   # should show ripgrep version
```

#### Install on macOS (Homebrew):
```bash
brew install jq ripgrep
```

#### Install on Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install jq ripgrep
```

**Note:** Ubuntu 18.04 ships with jq 1.5. If `jq --version` shows 1.5, install manually:
```bash
# Download jq 1.6 binary
wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod +x jq-linux64
sudo mv jq-linux64 /usr/local/bin/jq
```

#### Verify installation:
```bash
jq --version   # Should show 1.6 or higher
rg --version   # Should show ripgrep version
```

---

### Step 2: Install Kiro Memory System

Choose your installation method:

#### Option A: Clone this repository
```bash
cd /your/project/directory
git clone <repo-url> memory-system
cp -r memory-system/.kiro .
```

#### Option B: Copy .kiro directory directly
```bash
# If you have the memory-system files elsewhere:
cp -r /path/to/memory-system/.kiro /your/project/
```

---

### Step 3: Initialize Memory

```bash
cd /your/project
./.kiro/memory.sh init
```

**Expected output:**
```
Memory initialized at .kiro/memory/insights.json
```

If you see "Memory file already exists", that's normal - it means the `.kiro` directory came with a pre-initialized memory file.

---

## Quick Start

### Add Your First Insight

```bash
./.kiro/memory.sh add
```

You'll be prompted to enter:
1. **Category** (conventions, architecture, patterns, decisions, gotchas)
2. **Summary** - One-line description
3. **Content** - 2-4 sentence explanation
4. **Related files** - Optional comma-separated list
5. **Tags** - Optional comma-separated list

**Example:**
```
Select category:
  1) conventions
  2) architecture
  3) patterns
  4) decisions
  5) gotchas
Choice [1-5]: 1
Summary (one-line): Python uses snake_case for functions
Content (2-4 sentences): All function names use snake_case. Classes use PascalCase. Constants use UPPER_CASE.
Related files (comma-separated, or press Enter to skip): style-guide.md
Tags (comma-separated, or press Enter to skip): python, naming, convention

Insight added successfully!
```

---

## How Insights Are Retrieved

The key to Kiro Memory is **targeted retrieval** using `rg` (ripgrep).

### Manual Retrieval

#### Search by keyword:
```bash
./.kiro/memory.sh search "python"
```

#### Display all insights:
```bash
./.kiro/memory.sh show
```

#### Show memory statistics:
```bash
./.kiro/memory.sh status
```

### Automatic Retrieval (by Agents)

When an AI agent needs context, it searches for relevant insights:

```bash
# Agent searches for specific terms:
rg -A 5 -B 1 "python" .kiro/memory/insights.json

# Agent searches for multiple terms:
rg -A 5 -B 1 "naming" .kiro/memory/insights.json
rg -A 5 -B 1 "convention" .kiro/memory/insights.json
```

**Important:** The agent uses `rg`, not `cat` or `Read`. This ensures only relevant insights are loaded into context.

---

## How Insights Are Created

There are **two ways** to create insights:

### Method 1: Manual (via CLI)

```bash
./.kiro/memory.sh add
```

Follow the interactive prompts to add an insight. The script handles:
- Generating a unique ID from your summary
- Creating properly formatted JSON
- Updating metadata (total_insights, last_updated)

### Method 2: Automatic (via Agent Hooks)

When using **Kiro CLI** with an agent configured with memory hooks, insights can be captured automatically after each conversation.

#### How Automatic Capture Works

1. You complete a conversation with the agent
2. The **STOP hook** triggers `.kiro/hooks/memory-capture.sh`
3. The hook displays a reflection prompt to the agent
4. The agent decides if anything should be remembered
5. The agent manually adds insights to the JSON file

#### The Memory Reflection Prompt

After each conversation, the agent sees:

```
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
```

#### Important Notes

- **The hook is just a reminder** - it doesn't automatically create insights
- The agent must recognize something worth remembering and add it manually
- This design prevents capturing irrelevant information
- The agent's prompt includes detailed instructions on how to add insights

---

## Using with Kiro CLI

### Running with the Default Agent

If you have **Kiro CLI** installed, you can use the Default agent which comes pre-configured with memory hooks:

```bash
# Start chat with the Default agent (includes memory system)
kiro-cli chat Default

# Or resume a previous conversation
kiro-cli chat Default --resume
```

### What the Default Agent Does

The Default agent (`.kiro/agents/Default.json`) is configured to:

1. **BEFORE responding:**
   - Extract 2-4 search terms from your request
   - Use `rg` to search for relevant insights
   - Include only relevant memory in its response

2. **AFTER responding:**
   - Reflect on whether anything new was learned
   - Add insights if appropriate
   - Update metadata

### Agent Prompt Instructions

The Default agent's prompt includes:

```
## MEMORY SYSTEM

### BEFORE responding to user requests:
1. Extract 2-4 key search terms from user's request
2. Use rg to search ONLY matching sections
3. Combine relevant matches into brief context
4. Include ONLY relevant memory in response

### DO NOT:
- Read the entire insights.json file (it bloats context)
- Use Read tool on insights.json directly
- Include memories that don't match the search terms

### AFTER responding:
1. Ask: "Did I learn something new about this project?"
2. If yes, add an insight to the appropriate category
3. Check for duplicates using rg before adding
4. Update metadata.total_insights and metadata.last_updated
```

---

## Memory Categories

| Category | Purpose | Examples |
|----------|---------|----------|
| **conventions** | Code style, naming patterns, team standards | "Use snake_case for functions", "Max line length 100" |
| **architecture** | System design, component relationships | "Event-driven architecture", "Two-tier caching" |
| **patterns** | Idioms, common approaches | "Use context managers for resources", "Lazy initialization" |
| **decisions** | Why X was chosen over Y | "Chose SQLite over Postgres for simplicity", "No ORM decision" |
| **gotchas** | Common pitfalls, troubleshooting | "Never read full insights.json", "Circular import prevention" |

---

## Insight Format

Each insight stored in `.kiro/memory/insights.json`:

```json
{
  "id": "short-kebab-case",
  "summary": "One-line summary",
  "content": "Full explanation (2-4 sentences)",
  "files": ["related", "files"],
  "tags": ["relevant", "tags"],
  "created_at": "2026-02-16T15:30:00Z"
}
```

### Understanding "Related Files"

When you add a "related file" reference, the memory system stores that reference but **does not modify the original file**. The reference helps you:
- Find which files are related to which insights
- Navigate from an insight to relevant source files
- Track connections between code and decisions

**Example:** Adding an insight about "snake_case naming" and referencing `style-guide.md` stores the connection but doesn't change `style-guide.md` itself.

---

## CLI Commands Reference

```bash
./.kiro/memory.sh init      # Initialize memory for project
./.kiro/memory.sh status    # Show memory statistics
./.kiro/memory.sh show      # Display all insights
./.kiro/memory.sh search    # Search by keyword or tag
./.kiro/memory.sh add       # Manually add a new insight
./.kiro/memory.sh clear     # Clear all memory (requires confirmation)
```

---

## Git Integration

### Team-shared memory (commit to git):
```bash
git add .kiro/memory/insights.json
git commit -m "Update project memory"
git push
```

### Local-only memory (add to .gitignore):
```bash
echo ".kiro/memory/insights.json" >> .gitignore
```

### Benefits of Git-tracked Memory
- Version history shows evolution of decisions
- Team members get updates via `git pull`
- Code reviews include convention changes
- Rollback to previous conventions if needed

---

## File Structure

```
.your-project/
└── .kiro/
    ├── memory/
    │   └── insights.json          # Your memory storage
    ├── memory.sh                  # CLI commands
    ├── hooks/
    │   └── memory-capture.sh      # Auto-capture hook
    └── agents/
        └── Default.json           # Agent config with memory
```

---

## Troubleshooting

### "jq: error: trim/0 is not defined"

**Cause:** You have jq 1.5 or older. The `trim` function was added in jq 1.6.

**Fix:** Upgrade to jq 1.6+ using the installation instructions above.

### "Memory already exists" message

**Expected behavior:** This means you copied the `.kiro` directory which already contains an initialized memory file.

**What to do:** Use the suggested commands to interact with existing memory:
```bash
./.kiro/memory.sh status    # See what's in memory
./.kiro/memory.sh add       # Add new insights
```

### Added insight doesn't show in `show` command

**Possible causes:**
1. Check that `status` shows increased insight count
2. Verify you added to the category you're viewing
3. Run `show` again to refresh the display

### Related file wasn't modified

**Expected behavior:** Related files are **references only**. The memory system does not modify the original files. See "Understanding 'Related Files'" above.

---

## License

Part of the Kiro Immersion training materials.
