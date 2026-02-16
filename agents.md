# Agent Instructions

## Local Memory System

This project uses a code-free RAG (Retrieval-Augmented Generation) memory system to maintain context across sessions.

### When to Check Memory

**Before answering questions about:**
- Prior work or implementation patterns
- Project conventions or decisions
- Architecture choices made in previous sessions
- Known issues, gotchas, or troubleshooting tips

### How to Retrieve Memory

**NEVER read the entire `insights.json` file.** That wastes context space.

Instead, extract 2-4 key search terms from the user's request and use `rg`:

```bash
# Extract search terms from the request, then:
rg -A 5 -B 1 "search-term" .kiro/memory/insights.json
rg -A 5 -B 1 "another-term" .kiro/memory/insights.json
```

**Example:**
- User asks: "How do we handle CSS in this project?"
- Search terms: `css`, `style`, `frontend`
- Command: `rg -A 5 -B 1 "css" .kiro/memory/insights.json`

### How to Store Memory

After responding or learning something new:

1. **Check for duplicates first:**
   ```bash
   rg "similar-keyword" .kiro/memory/insights.json
   ```

2. **If new, add to insights.json** with this structure:
   ```json
   {
     "id": "short-kebab-case",
     "summary": "One-line summary",
     "content": "Full explanation (2-4 sentences)",
     "files": ["related", "files"],
     "tags": ["relevant", "tags"],
     "created_at": "2026-02-04T13:30:00Z"
   }
   ```

3. **Valid categories:**
   - `conventions`: Code style, naming patterns, standards
   - `architecture`: System design, component relationships
   - `patterns`: Idioms, common approaches
   - `decisions`: Why X was chosen over Y
   - `gotchas`: Common pitfalls, troubleshooting

### CLI Helpers

Use the memory script for common operations:

```bash
# Show memory statistics
.kiro/memory.sh status

# Display all insights
.kiro/memory.sh show

# Search by keyword
.kiro/memory.sh search "jwt"

# Manually add an insight
.kiro/memory.sh add
```

### Why This Approach

- **Minimal context usage**: Only relevant memories retrieved
- **Fast**: `rg` is optimized for search
- **No dependencies**: Pure grep-based, no ML required
- **Git-friendly**: Clean diffs, can version or `.gitignore`

### Design Philosophy

**Targeted retrieval > full file read**

The memory system captures things NOT visible in source code:
- Conventions (why we do things a certain way)
- Decisions (why we chose X over Y)
- Patterns (idioms specific to this codebase)
- Gotchas (things that broke before)

Use grep/rg to find only what's relevant. Preserve context for actual work.
