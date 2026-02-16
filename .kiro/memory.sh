#!/bin/bash
# kiro memory - CLI commands for project memory

MEMORY_DIR=".kiro/memory"
MEMORY_FILE="$MEMORY_DIR/insights.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure memory directory exists
init_memory() {
    if [ ! -f "$MEMORY_FILE" ]; then
        mkdir -p "$MEMORY_DIR"
        cat > "$MEMORY_FILE" << 'EOF'
{
  "metadata": {
    "version": "1.0",
    "last_updated": "2025-02-03T00:00:00Z",
    "total_insights": 0
  },
  "insights": {
    "conventions": [],
    "architecture": [],
    "patterns": [],
    "decisions": [],
    "gotchas": []
  }
}
EOF
        echo -e "${GREEN}Memory initialized at $MEMORY_FILE${NC}"
    else
        echo -e "${YELLOW}Memory already exists at $MEMORY_FILE${NC}"
    fi
}

# Show memory statistics
cmd_status() {
    if [ ! -f "$MEMORY_FILE" ]; then
        echo -e "${RED}Memory not found. Run 'kiro memory init' first.${NC}"
        return 1
    fi

    echo -e "${BLUE}=== Project Memory Status ===${NC}"
    echo ""
    echo "Location: $MEMORY_FILE"

    # Count insights per category
    for category in conventions architecture patterns decisions gotchas; do
        count=$(jq ".insights.$category | length" "$MEMORY_FILE" 2>/dev/null || echo "0")
        echo -e "  ${GREEN}$category:${NC} $count"
    done

    total=$(jq ".metadata.total_insights" "$MEMORY_FILE" 2>/dev/null || echo "0")
    updated=$(jq -r ".metadata.last_updated" "$MEMORY_FILE" 2>/dev/null || echo "unknown")
    echo ""
    echo "Total insights: $total"
    echo "Last updated: $updated"
}

# Display all insights
cmd_show() {
    if [ ! -f "$MEMORY_FILE" ]; then
        echo -e "${RED}Memory not found. Run 'kiro memory init' first.${NC}"
        return 1
    fi

    echo -e "${BLUE}=== Project Memory ===${NC}"
    echo ""

    for category in conventions architecture patterns decisions gotchas; do
        count=$(jq ".insights.$category | length" "$MEMORY_FILE" 2>/dev/null || echo "0")
        if [ "$count" -gt 0 ]; then
            echo -e "${GREEN}## $category ($count)${NC}"
            jq -r ".insights.$category[] | \"### \(.summary)\\n  \(.content)\\n  Files: \(.files | join(\", \"))\\n  Tags: \(.tags | join(\", \"))\\n  Created: \(.created_at)\\n\"" "$MEMORY_FILE" 2>/dev/null
            echo ""
        fi
    done
}

# Search memory by keyword or tag
cmd_search() {
    local query="$1"

    if [ -z "$query" ]; then
        echo -e "${RED}Usage: kiro memory search <keyword or tag>${NC}"
        return 1
    fi

    if [ ! -f "$MEMORY_FILE" ]; then
        echo -e "${RED}Memory not found. Run 'kiro memory init' first.${NC}"
        return 1
    fi

    echo -e "${BLUE}=== Search Results for: $query ===${NC}"
    echo ""

    local found=0

    for category in conventions architecture patterns decisions gotchas; do
        local results=$(jq -r --arg q "$query" \
            ".insights.$category[] | select(.summary | ascii_downcase | contains(\$q | ascii_downcase)) | \
            \"\(.summary) | \(.category)\"" \
            "$MEMORY_FILE" 2>/dev/null)

        if [ -n "$results" ]; then
            echo -e "${GREEN}$category:${NC}"
            echo "$results"
            echo ""
            found=1
        fi
    done

    if [ "$found" -eq 0 ]; then
        echo -e "${YELLOW}No insights found matching '$query'${NC}"
    fi
}

# Add a new insight manually
cmd_add() {
    if [ ! -f "$MEMORY_FILE" ]; then
        echo -e "${RED}Memory not found. Run 'kiro memory init' first.${NC}"
        return 1
    fi

    echo -e "${BLUE}=== Add New Insight ===${NC}"
    echo ""

    # Get category
    echo "Select category:"
    echo "  1) conventions"
    echo "  2) architecture"
    echo "  3) patterns"
    echo "  4) decisions"
    echo "  5) gotchas"
    read -p "Choice [1-5]: " choice

    case $choice in
        1) category="conventions" ;;
        2) category="architecture" ;;
        3) category="patterns" ;;
        4) category="decisions" ;;
        5) category="gotchas" ;;
        *) echo -e "${RED}Invalid choice${NC}"; return 1 ;;
    esac

    read -p "Summary (one-line): " summary
    read -p "Content (2-4 sentences): " content
    read -p "Related files (comma-separated, or press Enter to skip): " files
    read -p "Tags (comma-separated, or press Enter to skip): " tags

    # Build JSON
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local id=$(echo "$summary" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')

    # Create temp file for JSON construction
    local tmpfile=$(mktemp)

    # Build arrays for files and tags
    local files_json="[]"
    local tags_json="[]"

    if [ -n "$files" ]; then
        files_json=$(echo "$files" | jq -R 'split(",") | map(gsub("^\\s+|\\s+$";""))')
    fi

    if [ -n "$tags" ]; then
        tags_json=$(echo "$tags" | jq -R 'split(",") | map(gsub("^\\s+|\\s+$";""))')
    fi

    # Create new insight
    local new_insight=$(jq -n \
        --arg id "$id" \
        --arg summary "$summary" \
        --arg content "$content" \
        --arg created "$timestamp" \
        --argjson files "$files_json" \
        --argjson tags "$tags_json" \
        '{id: $id, summary: $summary, content: $content, files: $files, tags: $tags, created_at: $created}')

    # Add to memory file
    jq --arg category "$category" --argjson insight "$new_insight" \
        '.insights[$category] += [$insight] | .metadata.total_insights += 1 | .metadata.last_updated = now | tostring |= .[0:19] + "Z"' \
        "$MEMORY_FILE" > "$tmpfile" && mv "$tmpfile" "$MEMORY_FILE"

    echo ""
    echo -e "${GREEN}Insight added successfully!${NC}"
}

# Clear all memory
cmd_clear() {
    if [ ! -f "$MEMORY_FILE" ]; then
        echo -e "${RED}Memory not found.${NC}"
        return 1
    fi

    read -p "Are you sure you want to clear all memory? [y/N]: " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        cat > "$MEMORY_FILE" << 'EOF'
{
  "metadata": {
    "version": "1.0",
    "last_updated": "2025-02-03T00:00:00Z",
    "total_insights": 0
  },
  "insights": {
    "conventions": [],
    "architecture": [],
    "patterns": [],
    "decisions": [],
    "gotchas": []
  }
}
EOF
        echo -e "${GREEN}Memory cleared.${NC}"
    else
        echo "Aborted."
    fi
}

# Show help
cmd_help() {
    echo "kiro memory - Project memory management"
    echo ""
    echo "Usage: kiro memory <command>"
    echo ""
    echo "Commands:"
    echo "  init      Initialize memory for this project"
    echo "  status    Show memory statistics"
    echo "  show      Display all insights"
    echo "  search    Search by keyword or tag"
    echo "  add       Manually add a new insight"
    echo "  clear     Clear all memory (requires confirmation)"
    echo "  help      Show this help message"
}

# Main command dispatcher
case "${1:-help}" in
    init)   init_memory ;;
    status) cmd_status ;;
    show)   cmd_show ;;
    search) cmd_search "$2" ;;
    add)    cmd_add ;;
    clear)  cmd_clear ;;
    help|--help|-h) cmd_help ;;
    *)      echo -e "${RED}Unknown command: $1${NC}"; echo ""; cmd_help ;;
esac
