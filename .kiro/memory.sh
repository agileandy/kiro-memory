#!/bin/bash
# kiro memory - CLI commands for project memory

MEMORY_DIR=".kiro/memory"
CONFIG_FILE=".kiro/settings/config.json"

# Read memory file location from config, default to insights.json
if [ -f "$CONFIG_FILE" ]; then
    MEMORY_FILE=$(jq -r '.memory_file // ".kiro/memory/insights.json"' "$CONFIG_FILE" 2>/dev/null)
else
    MEMORY_FILE=".kiro/memory/insights.json"
fi

VERBOSE="${KIRO_MEMORY_VERBOSE:-true}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure memory directory exists
init_memory() {
    if [ ! -f "$MEMORY_FILE" ]; then
        mkdir -p "$(dirname "$MEMORY_FILE")"
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
        echo ""
        echo -e "${BLUE}Tip:${NC} Sample insights available at .kiro/memory/sample-insights.json"
        echo -e "     Use '.kiro/memory.sh import-samples' to copy them to your memory file"
    else
        echo -e "${YELLOW}Memory file already exists at $MEMORY_FILE${NC}"
        echo -e "  Use '${GREEN}.kiro/memory.sh status${NC}' to see current memory"
        echo -e "  Use '${GREEN}.kiro/memory.sh add${NC}' to add new insights"
        echo -e "  Use '${GREEN}.kiro/memory.sh show${NC}' to display all insights"
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

# Search memory by keyword or tag (searches summary, content, and tags)
cmd_search() {
    local query="$1"

    if [ -z "$query" ]; then
        echo -e "${RED}Usage: .kiro/memory.sh search <keyword>${NC}"
        return 1
    fi

    if [ ! -f "$MEMORY_FILE" ]; then
        echo -e "${RED}Memory not found. Run '.kiro/memory.sh init' first.${NC}"
        return 1
    fi

    echo -e "${BLUE}=== Search Results for: $query ===${NC}"
    echo ""

    local found=0

    # Search through all insights using jq
    for category in conventions architecture patterns decisions gotchas; do
        local results=$(jq -r --arg q "$query" ".insights.$category[] | select(
            (.summary | ascii_downcase | contains(\$q | ascii_downcase)) or
            (.content | ascii_downcase | contains(\$q | ascii_downcase)) or
            (.tags | map(ascii_downcase) | any(contains(\$q | ascii_downcase)))
        ) | \"ID: \(.id)\nSummary: \(.summary)\nContent: \(.content)\nTags: \(.tags | join(\", \"))\n\"" "$MEMORY_FILE" 2>/dev/null)

        if [ -n "$results" ]; then
            echo "$results"
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

    # Check for duplicate ID and auto-increment if needed
    local original_id="$id"
    local counter=2
    while true; do
        local existing=$(jq -r --arg id "$id" '.insights[][] | select(.id == $id) | .id' "$MEMORY_FILE" 2>/dev/null)
        if [ -z "$existing" ]; then
            break
        fi
        id="${original_id}-${counter}"
        ((counter++))
    done

    if [ "$id" != "$original_id" ]; then
        [ "$VERBOSE" = "true" ] && echo -e "${YELLOW}Note: ID adjusted to '$id' to avoid duplicate${NC}"
    fi

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
        '.insights[$category] += [$insight] | 
         .metadata.total_insights += 1 | 
         .metadata.last_updated = (now | strftime("%Y-%m-%dT%H:%M:%SZ"))' \
        "$MEMORY_FILE" > "$tmpfile" && mv "$tmpfile" "$MEMORY_FILE"

    if [ "$VERBOSE" = "true" ]; then
        echo ""
        echo -e "${GREEN}✓ Insight added successfully!${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "  ID: ${YELLOW}$id${NC}"
        echo -e "  Category: ${YELLOW}$category${NC}"
        echo -e "  Summary: $summary"
        if [ ${#tags_json} -gt 2 ]; then
            echo -e "  Tags: $(echo "$tags_json" | jq -r 'join(", ")')"
        fi
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi
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

# Test if a memory is retrievable
cmd_test() {
    local memory_id="$1"
    shift

    if [[ -z "$memory_id" ]]; then
        echo -e "${RED}Usage: .kiro/memory.sh test <memory-id> <search-term1> <search-term2> ...${NC}"
        echo ""
        echo "Tests if a memory would be found with different search terms."
        echo ""
        echo "Example:"
        echo "  .kiro/memory.sh test snake-case-naming python function naming"
        return 1
    fi

    if [[ ! -f "$MEMORY_FILE" ]]; then
        echo -e "${RED}Memory not found. Run 'kiro memory init' first.${NC}"
        return 1
    fi

    if [[ $# -eq 0 ]]; then
        echo -e "${YELLOW}Warning: No search terms provided. Testing with common terms...${NC}"
        # Extract tags from the memory to use as search terms
        local tags=$(jq -r --arg id "$memory_id" '.insights[][] | select(.id == $id) | .tags[]' "$MEMORY_FILE" 2>/dev/null)
        if [[ -z "$tags" ]]; then
            echo -e "${RED}Memory '$memory_id' not found or has no tags.${NC}"
            return 1
        fi
        SEARCH_TERMS=($(echo "$tags"))
    else
        SEARCH_TERMS=("$@")
    fi

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📝 Testing Memory: $memory_id${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Extract the memory
    local memory_json=$(jq -r --arg id "$memory_id" '.insights[][] | select(.id == $id)' "$MEMORY_FILE" 2>/dev/null)

    if [[ -z "$memory_json" ]]; then
        echo -e "${RED}Memory with ID '$memory_id' not found.${NC}"
        echo ""
        echo "Available memory IDs:"
        jq -r '.insights[][] | .id' "$MEMORY_FILE" | sort -u
        return 1
    fi

    # Display memory details
    echo -e "${GREEN}Memory Content:${NC}"
    echo "$memory_json" | jq -r '"  Summary: \(.summary)\n  Content: \(.content)\n  Tags: \(.tags | join(", "))"'
    echo ""

    # Test each search term
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🔍 Search Term Tests${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    local found_count=0
    local total_count=${#SEARCH_TERMS[@]}

    for term in "${SEARCH_TERMS[@]}"; do
        local match=$(rg -i -C 20 "$term" "$MEMORY_FILE" 2>/dev/null | grep -q "\"id\": \"$memory_id\"" && echo "yes" || echo "no")

        if [[ "$match" == "yes" ]]; then
            echo -e "  ${GREEN}✅ '$term' → FOUND${NC}"
            ((found_count++))
        else
            echo -e "  ${RED}❌ '$term' → NOT FOUND${NC}"
        fi
    done

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📊 Results: $found_count/$total_count search terms would find this memory${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [[ $found_count -eq $total_count ]]; then
        echo ""
        echo -e "${GREEN}✅ Great! All search terms work.${NC}"
        return 0
    elif [[ $found_count -gt $((total_count / 2)) ]]; then
        echo ""
        echo -e "${YELLOW}⚠️  Some search terms missing. Consider adding them to content or tags.${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}❌ Most search terms fail! This memory won't be found easily.${NC}"
        echo ""
        echo "Suggested fixes:"
        echo "  1. Add missing terms to the content field"
        echo "  2. Add missing terms to the tags array"
        echo "  3. Rewrite summary to include primary keywords"
        return 1
    fi
}

# List insights (compact view)
cmd_list() {
    local category="$1"

    if [ ! -f "$MEMORY_FILE" ]; then
        echo -e "${RED}Memory not found. Run '.kiro/memory.sh init' first.${NC}"
        return 1
    fi

    if [ -n "$category" ]; then
        # List specific category
        local count=$(jq ".insights.$category | length" "$MEMORY_FILE" 2>/dev/null || echo "0")
        if [ "$count" -eq 0 ]; then
            echo -e "${YELLOW}No insights in category '$category'${NC}"
            return 0
        fi
        echo -e "${GREEN}$category ($count):${NC}"
        jq -r ".insights.$category[] | \"  \(.id) - \(.summary)\"" "$MEMORY_FILE" 2>/dev/null
    else
        # List all categories
        echo -e "${BLUE}=== All Insights ===${NC}"
        echo ""
        for cat in conventions architecture patterns decisions gotchas; do
            local count=$(jq ".insights.$cat | length" "$MEMORY_FILE" 2>/dev/null || echo "0")
            if [ "$count" -gt 0 ]; then
                echo -e "${GREEN}$cat ($count):${NC}"
                jq -r ".insights.$cat[] | \"  \(.id) - \(.summary)\"" "$MEMORY_FILE" 2>/dev/null
                echo ""
            fi
        done
    fi
}

# Remove an insight
cmd_remove() {
    local memory_id="$1"

    if [ -z "$memory_id" ]; then
        echo -e "${RED}Usage: .kiro/memory.sh remove <memory-id>${NC}"
        return 1
    fi

    if [ ! -f "$MEMORY_FILE" ]; then
        echo -e "${RED}Memory not found. Run '.kiro/memory.sh init' first.${NC}"
        return 1
    fi

    # Check if insight exists
    local existing=$(jq -r --arg id "$memory_id" '.insights[][] | select(.id == $id) | .id' "$MEMORY_FILE" 2>/dev/null)
    if [ -z "$existing" ]; then
        echo -e "${RED}Error: No insight found with ID '$memory_id'${NC}"
        return 1
    fi

    # Show what will be removed
    echo -e "${YELLOW}Removing insight:${NC}"
    jq -r --arg id "$memory_id" '.insights[][] | select(.id == $id) | "  Summary: \(.summary)\n  Content: \(.content)"' "$MEMORY_FILE" 2>/dev/null
    echo ""

    read -p "Are you sure? [y/N]: " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Aborted."
        return 0
    fi

    # Remove the insight
    local tmpfile=$(mktemp)
    jq --arg id "$memory_id" '
        .insights.conventions |= map(select(.id != $id)) |
        .insights.architecture |= map(select(.id != $id)) |
        .insights.patterns |= map(select(.id != $id)) |
        .insights.decisions |= map(select(.id != $id)) |
        .insights.gotchas |= map(select(.id != $id)) |
        .metadata.total_insights = ([.insights[][]] | length) |
        .metadata.last_updated = (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
    ' "$MEMORY_FILE" > "$tmpfile" && mv "$tmpfile" "$MEMORY_FILE"

    echo -e "${GREEN}Insight removed successfully.${NC}"
}

# Edit an insight
cmd_edit() {
    local memory_id="$1"

    if [ -z "$memory_id" ]; then
        echo -e "${RED}Usage: .kiro/memory.sh edit <memory-id>${NC}"
        return 1
    fi

    if [ ! -f "$MEMORY_FILE" ]; then
        echo -e "${RED}Memory not found. Run '.kiro/memory.sh init' first.${NC}"
        return 1
    fi

    # Check if insight exists
    local insight=$(jq -r --arg id "$memory_id" '.insights[][] | select(.id == $id)' "$MEMORY_FILE" 2>/dev/null)
    if [ -z "$insight" ]; then
        echo -e "${RED}Error: No insight found with ID '$memory_id'${NC}"
        return 1
    fi

    # Extract current values
    local current_summary=$(echo "$insight" | jq -r '.summary')
    local current_content=$(echo "$insight" | jq -r '.content')
    local current_files=$(echo "$insight" | jq -r '.files | join(", ")')
    local current_tags=$(echo "$insight" | jq -r '.tags | join(", ")')

    echo -e "${BLUE}=== Edit Insight: $memory_id ===${NC}"
    echo ""
    echo -e "Current summary: ${YELLOW}$current_summary${NC}"
    read -p "New summary (or press Enter to keep): " new_summary
    [ -z "$new_summary" ] && new_summary="$current_summary"

    echo -e "Current content: ${YELLOW}$current_content${NC}"
    read -p "New content (or press Enter to keep): " new_content
    [ -z "$new_content" ] && new_content="$current_content"

    echo -e "Current files: ${YELLOW}$current_files${NC}"
    read -p "New files (comma-separated, or press Enter to keep): " new_files
    [ -z "$new_files" ] && new_files="$current_files"

    echo -e "Current tags: ${YELLOW}$current_tags${NC}"
    read -p "New tags (comma-separated, or press Enter to keep): " new_tags
    [ -z "$new_tags" ] && new_tags="$current_tags"

    # Build arrays
    local files_json="[]"
    local tags_json="[]"

    if [ -n "$new_files" ]; then
        files_json=$(echo "$new_files" | jq -R 'split(",") | map(gsub("^\\s+|\\s+$";""))')
    fi

    if [ -n "$new_tags" ]; then
        tags_json=$(echo "$new_tags" | jq -R 'split(",") | map(gsub("^\\s+|\\s+$";""))')
    fi

    # Update the insight
    local tmpfile=$(mktemp)
    jq --arg id "$memory_id" \
       --arg summary "$new_summary" \
       --arg content "$new_content" \
       --argjson files "$files_json" \
       --argjson tags "$tags_json" '
        (.insights[][] | select(.id == $id)) |= {
            id: .id,
            summary: $summary,
            content: $content,
            files: $files,
            tags: $tags,
            created_at: .created_at
        } |
        .metadata.last_updated = (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
    ' "$MEMORY_FILE" > "$tmpfile" && mv "$tmpfile" "$MEMORY_FILE"

    echo ""
    echo -e "${GREEN}Insight updated successfully.${NC}"
}

# Show help
cmd_help() {
    echo "kiro memory - Project memory management"
    echo ""
    echo "Usage: .kiro/memory.sh <command>"
    echo ""
    echo "Commands:"
    echo "  init              Initialize memory for this project"
    echo "  status            Show memory statistics"
    echo "  list [category]   List all insights (compact view)"
    echo "  show              Display all insights (detailed view)"
    echo "  search <keyword>  Search by keyword in summary, content, and tags"
    echo "  add               Manually add a new insight"
    echo "  edit <id>         Edit an existing insight"
    echo "  remove <id>       Remove an insight"
    echo "  import-samples    Import insights from sample-insights.json"
    echo "  test <id> [...]   Test if a memory is retrievable with search terms"
    echo "  clear             Clear all memory (requires confirmation)"
    echo "  version           Show version information"
    echo "  help              Show this help message"
    echo ""
    echo "Current memory file: $MEMORY_FILE"
}

# Show version information
cmd_version() {
    local version_file=".kiro/VERSION"
    local local_version_file=".kiro/.version-local"
    
    if [ -f "$version_file" ]; then
        local version=$(cat "$version_file")
        echo -e "${BLUE}Kiro Memory System${NC}"
        echo -e "Version: ${GREEN}$version${NC}"
        echo ""
        
        if [ -f "$local_version_file" ]; then
            echo -e "${BLUE}Local Installation:${NC}"
            jq -r '"  Installed: \(.installed_date)\n  Last Updated: \(.last_updated)\n  Custom Modifications: \(.custom_modifications)"' "$local_version_file"
        fi
        
        echo ""
        echo "See docs/CHANGELOG.md for version history and changes."
    else
        echo -e "${YELLOW}Version file not found.${NC}"
        echo "This may be a development version."
    fi
}

# Import sample insights
cmd_import_samples() {
    local sample_file=".kiro/memory/sample-insights.json"
    
    if [ ! -f "$sample_file" ]; then
        echo -e "${RED}Sample insights file not found at $sample_file${NC}"
        return 1
    fi
    
    if [ ! -f "$MEMORY_FILE" ]; then
        echo -e "${YELLOW}Memory file doesn't exist. Run '.kiro/memory.sh init' first.${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Importing sample insights...${NC}"
    echo ""
    
    # Merge sample insights into user's memory file
    local tmpfile=$(mktemp)
    jq -s '
        .[0] as $user |
        .[1] as $samples |
        $user |
        .insights.conventions += $samples.insights.conventions |
        .insights.architecture += $samples.insights.architecture |
        .insights.patterns += $samples.insights.patterns |
        .insights.decisions += $samples.insights.decisions |
        .insights.gotchas += $samples.insights.gotchas |
        .metadata.total_insights = ([.insights[][]] | length) |
        .metadata.last_updated = (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
    ' "$MEMORY_FILE" "$sample_file" > "$tmpfile" && mv "$tmpfile" "$MEMORY_FILE"
    
    local count=$(jq '[.insights[][]] | length' "$sample_file")
    echo -e "${GREEN}✓ Imported $count sample insights${NC}"
    echo ""
    echo -e "${YELLOW}Note:${NC} This may create duplicates if samples were already imported."
    echo -e "      Use '.kiro/memory.sh list' to review and '.kiro/memory.sh remove <id>' to clean up."
}

# Main command dispatcher
case "${1:-help}" in
    init)   init_memory ;;
    status) cmd_status ;;
    list)   cmd_list "$2" ;;
    show)   cmd_show ;;
    search) cmd_search "$2" ;;
    add)    cmd_add ;;
    edit)   cmd_edit "$2" ;;
    remove) cmd_remove "$2" ;;
    import-samples) cmd_import_samples ;;
    test)   shift; cmd_test "$@" ;;
    clear)  cmd_clear ;;
    version) cmd_version ;;
    help|--help|-h) cmd_help ;;
    *)      echo -e "${RED}Unknown command: $1${NC}"; echo ""; cmd_help ;;
esac
