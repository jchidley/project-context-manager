#!/bin/bash
# Script to migrate SQLite todos to plain text TODO.md format

set -euo pipefail

PC_HOME="${HOME}/.project-contexts"
TODOS_DB="${PC_HOME}/todos.db"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Starting migration from SQLite to plain text TODO.md files..."

# Check if database exists
if [[ ! -f "$TODOS_DB" ]]; then
    echo "No todos database found at $TODOS_DB"
    exit 1
fi

# Get all unique contexts with todos
contexts=$(sqlite3 "$TODOS_DB" "SELECT DISTINCT context FROM todos ORDER BY context;")

if [[ -z "$contexts" ]]; then
    echo "No todos found in database"
    exit 0
fi

# Process each context
echo "$contexts" | while read -r context; do
    if [[ -z "$context" ]]; then
        continue
    fi
    
    echo -e "${GREEN}Processing context: $context${NC}"
    
    # Create context directory if it doesn't exist
    context_dir="${PC_HOME}/${context}"
    mkdir -p "$context_dir"
    
    todo_file="${context_dir}/TODO.md"
    
    # Create backup if TODO.md already exists
    if [[ -f "$todo_file" ]]; then
        backup_file="${todo_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$todo_file" "$backup_file"
        echo "  Backed up existing TODO.md to $backup_file"
    fi
    
    # Start writing the new TODO.md
    {
        echo "# TODO - $context"
        echo ""
        echo "Last updated: $(date '+%Y-%m-%d %H:%M')"
        echo ""
        
        # Export high priority / in progress todos
        in_progress=$(sqlite3 -separator $'\t' "$TODOS_DB" "
            SELECT id, title, github_issue, created_at
            FROM todos
            WHERE context = '$context' AND status = 'in_progress'
            ORDER BY priority DESC, created_at ASC;
        ")
        
        if [[ -n "$in_progress" ]]; then
            echo "## In Progress"
            echo ""
            echo "$in_progress" | while IFS=$'\t' read -r id title issue created; do
                if [[ -n "$issue" ]]; then
                    echo "- [ ] $title (#$issue) <!-- id:$id created:$created -->"
                else
                    echo "- [ ] $title <!-- id:$id created:$created -->"
                fi
            done
            echo ""
        fi
        
        # Export todo items
        todos=$(sqlite3 -separator $'\t' "$TODOS_DB" "
            SELECT id, title, github_issue, created_at
            FROM todos
            WHERE context = '$context' AND status = 'todo'
            ORDER BY priority DESC, created_at ASC;
        ")
        
        if [[ -n "$todos" ]]; then
            echo "## To Do"
            echo ""
            echo "$todos" | while IFS=$'\t' read -r id title issue created; do
                if [[ -n "$issue" ]]; then
                    echo "- [ ] $title (#$issue) <!-- id:$id created:$created -->"
                else
                    echo "- [ ] $title <!-- id:$id created:$created -->"
                fi
            done
            echo ""
        fi
        
        # Export completed items (last 20)
        completed=$(sqlite3 -separator $'\t' "$TODOS_DB" "
            SELECT id, title, github_issue, updated_at
            FROM todos
            WHERE context = '$context' AND status = 'done'
            ORDER BY updated_at DESC
            LIMIT 20;
        ")
        
        if [[ -n "$completed" ]]; then
            echo "## Completed (Recent)"
            echo ""
            echo "$completed" | while IFS=$'\t' read -r id title issue updated; do
                if [[ -n "$issue" ]]; then
                    echo "- [x] $title (#$issue) <!-- id:$id completed:$updated -->"
                else
                    echo "- [x] $title <!-- id:$id completed:$updated -->"
                fi
            done
            echo ""
        fi
        
    } > "$todo_file"
    
    echo -e "  ${GREEN}✓${NC} Created $todo_file"
    
    # Show summary
    todo_count=$(sqlite3 "$TODOS_DB" "SELECT COUNT(*) FROM todos WHERE context = '$context' AND status = 'todo';")
    in_progress_count=$(sqlite3 "$TODOS_DB" "SELECT COUNT(*) FROM todos WHERE context = '$context' AND status = 'in_progress';")
    done_count=$(sqlite3 "$TODOS_DB" "SELECT COUNT(*) FROM todos WHERE context = '$context' AND status = 'done';")
    
    echo -e "  Summary: $todo_count todo, $in_progress_count in progress, $done_count done"
done

echo ""
echo -e "${GREEN}Migration complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Review the generated TODO.md files in each context directory"
echo "2. The original database is preserved at $TODOS_DB"
echo "3. Run the new plain-text version of pc to continue working"