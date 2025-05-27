#!/usr/bin/env bash
# lib/todo_commands.sh - Todo management commands for pc

# Main todo command dispatcher
cmd_todo() {
    local subcommand="${1:-list}"
    shift || true
    
    case "$subcommand" in
        add)
            todo_add "$@"
            ;;
        complete|done)
            todo_complete "$@"
            ;;
        list|ls)
            todo_list "$@"
            ;;
        progress|status)
            todo_progress "$@"
            ;;
        search|grep)
            todo_search "$@"
            ;;
        move)
            todo_move "$@"
            ;;
        archive)
            todo_archive "$@"
            ;;
        *)
            error "Unknown todo subcommand: $subcommand"
            echo "Available subcommands: add, complete, list, progress, search, move, archive"
            return 1
            ;;
    esac
}

# Add a new todo
todo_add() {
    local context=$(get_current_context)
    if [[ -z "$context" ]]; then
        error "No active context"
        return 1
    fi
    
    local text="$*"
    if [[ -z "$text" ]]; then
        error "Todo text required"
        echo "Usage: pc todo add <text>"
        return 1
    fi
    
    local todo_file="${PC_DIR}/${context}/TODO.md"
    local date=$(get_date)
    
    # Ensure file exists with proper structure
    if [[ ! -f "$todo_file" ]]; then
        cat > "$todo_file" << EOF
# TODO - $context

Last updated: $(get_timestamp)

## To Do

## In Progress

## Done
EOF
    fi
    
    # Add to "To Do" section
    if grep -q "^## To Do" "$todo_file"; then
        # Insert after "## To Do" header, preserving blank line
        local temp_file="${todo_file}.tmp"
        awk -v todo="- [ ] $text <!-- created:$date -->" '
            /^## To Do/ { print; print ""; print todo; found=1; next }
            found && /^$/ { found=0 }
            { print }
        ' "$todo_file" > "$temp_file"
        mv "$temp_file" "$todo_file"
    else
        # Append to file
        echo -e "\n- [ ] $text <!-- created:$date -->" >> "$todo_file"
    fi
    
    # Update timestamp
    sed -i "s/^Last updated:.*/Last updated: $(get_timestamp)/" "$todo_file"
    
    add_to_history "todo-add" "$text"
    success "Added todo: $text"
}

# Complete a todo
todo_complete() {
    local context=$(get_current_context)
    if [[ -z "$context" ]]; then
        error "No active context"
        return 1
    fi
    
    local pattern="$*"
    if [[ -z "$pattern" ]]; then
        error "Search pattern required"
        echo "Usage: pc todo complete <pattern>"
        return 1
    fi
    
    local todo_file="${PC_DIR}/${context}/TODO.md"
    
    if [[ ! -f "$todo_file" ]]; then
        error "No todos found"
        return 1
    fi
    
    # Count matches
    local matches
    matches=$(grep "^- \[ \] .*${pattern}" "$todo_file" 2>/dev/null | wc -l || echo 0)
    
    if [[ $matches -eq 0 ]]; then
        error "No uncompleted todo found matching: $pattern"
        return 1
    elif [[ $matches -gt 1 ]]; then
        warn "Multiple todos match pattern: $pattern"
        echo "Matching todos:"
        grep -n "^- \[ \] .*${pattern}" "$todo_file" | sed 's/^/  /'
        echo -n "Complete all? [y/N] "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    local escaped_pattern=$(escape_regex "$pattern")
    local date=$(get_date)
    
    # Complete matching todos
    sed -i "s/^- \[ \] \(.*${escaped_pattern}.*\)$/- [x] \1 <!-- completed:$date -->/" "$todo_file"
    
    # Update timestamp
    sed -i "s/^Last updated:.*/Last updated: $(get_timestamp)/" "$todo_file"
    
    add_to_history "todo-complete" "$pattern"
    success "Completed $matches todo(s) matching: $pattern"
}

# List todos
todo_list() {
    local context=$(get_current_context)
    if [[ -z "$context" ]]; then
        error "No active context"
        return 1
    fi
    
    local todo_file="${PC_DIR}/${context}/TODO.md"
    
    if [[ ! -f "$todo_file" ]]; then
        info "No todos found"
        return 0
    fi
    
    display_file "$todo_file" "TODO - $context"
}

# Show todo progress by section
todo_progress() {
    local context=$(get_current_context)
    if [[ -z "$context" ]]; then
        error "No active context"
        return 1
    fi
    
    local todo_file="${PC_DIR}/${context}/TODO.md"
    
    if [[ ! -f "$todo_file" ]]; then
        info "No todos found"
        return 0
    fi
    
    echo -e "${BOLD}TODO Progress - $context${NC}\n"
    
    # Count todos in each state
    local todo_count=$(grep -c "^- \[ \]" "$todo_file" 2>/dev/null || echo 0)
    local done_count=$(grep -c "^- \[x\]" "$todo_file" 2>/dev/null || echo 0)
    local total_count=$((todo_count + done_count))
    
    if [[ $total_count -gt 0 ]]; then
        local percent=$((done_count * 100 / total_count))
        echo -e "${BOLD}Overall:${NC} $done_count/$total_count ($percent% complete)\n"
    fi
    
    # Show each section
    for section in "To Do" "In Progress" "Done"; do
        if grep -q "^## $section" "$todo_file"; then
            echo -e "${BLUE}## $section${NC}"
            
            # Extract todos from section
            sed -n "/^## $section/,/^##/{/^##/d; /^- \[/p}" "$todo_file" | head -10
            
            local count=$(sed -n "/^## $section/,/^##/{/^##/d; /^- \[/p}" "$todo_file" | wc -l)
            if [[ $count -gt 10 ]]; then
                echo "  ... and $((count - 10)) more"
            fi
            echo
        fi
    done
}

# Search todos
todo_search() {
    local context=$(get_current_context)
    if [[ -z "$context" ]]; then
        error "No active context"
        return 1
    fi
    
    local pattern="$*"
    if [[ -z "$pattern" ]]; then
        error "Search pattern required"
        echo "Usage: pc todo search <pattern>"
        return 1
    fi
    
    local todo_file="${PC_DIR}/${context}/TODO.md"
    
    if [[ ! -f "$todo_file" ]]; then
        info "No todos found"
        return 0
    fi
    
    echo -e "${BOLD}Searching todos for: $pattern${NC}\n"
    
    local found=false
    
    # Search in each section
    for section in "To Do" "In Progress" "Done"; do
        local matches=$(sed -n "/^## $section/,/^##/{/^##/d; /^- \[/p}" "$todo_file" | grep -i "$pattern" || true)
        
        if [[ -n "$matches" ]]; then
            if [[ "$found" == false ]]; then
                found=true
            fi
            echo -e "${BLUE}## $section${NC}"
            echo "$matches"
            echo
        fi
    done
    
    if [[ "$found" == false ]]; then
        info "No todos found matching: $pattern"
    fi
}

# Move todo between sections
todo_move() {
    local context=$(get_current_context)
    if [[ -z "$context" ]]; then
        error "No active context"
        return 1
    fi
    
    local pattern="${1:-}"
    local target="${2:-}"
    
    if [[ -z "$pattern" ]] || [[ -z "$target" ]]; then
        error "Pattern and target section required"
        echo "Usage: pc todo move <pattern> <to-do|in-progress|done>"
        return 1
    fi
    
    # Normalize target section
    case "${target,,}" in
        "to-do"|"todo"|"to do")
            target="To Do"
            ;;
        "in-progress"|"inprogress"|"in progress"|"progress")
            target="In Progress"
            ;;
        "done"|"completed"|"complete")
            target="Done"
            ;;
        *)
            error "Invalid target section: $target"
            echo "Valid sections: to-do, in-progress, done"
            return 1
            ;;
    esac
    
    local todo_file="${PC_DIR}/${context}/TODO.md"
    
    if [[ ! -f "$todo_file" ]]; then
        error "No todos found"
        return 1
    fi
    
    # Find matching todo
    local todo_line=$(grep "^- \[.\] .*${pattern}" "$todo_file" | head -1)
    
    if [[ -z "$todo_line" ]]; then
        error "No todo found matching: $pattern"
        return 1
    fi
    
    # Remove from current location
    local temp_file="${todo_file}.tmp"
    grep -v "^${todo_line}$" "$todo_file" > "$temp_file"
    
    # Add to target section
    awk -v todo="$todo_line" -v section="## $target" '
        $0 == section { print; print ""; print todo; found=1; next }
        found && /^$/ { found=0 }
        { print }
    ' "$temp_file" > "$todo_file"
    
    rm -f "$temp_file"
    
    # Update timestamp
    sed -i "s/^Last updated:.*/Last updated: $(get_timestamp)/" "$todo_file"
    
    add_to_history "todo-move" "$pattern to $target"
    success "Moved todo to $target: $todo_line"
}

# Archive completed todos
todo_archive() {
    local context=$(get_current_context)
    if [[ -z "$context" ]]; then
        error "No active context"
        return 1
    fi
    
    local todo_file="${PC_DIR}/${context}/TODO.md"
    local archive_file="${PC_DIR}/${context}/TODO_ARCHIVE.md"
    
    if [[ ! -f "$todo_file" ]]; then
        info "No todos to archive"
        return 0
    fi
    
    # Count completed todos
    local done_count=$(grep -c "^- \[x\]" "$todo_file" 2>/dev/null || echo 0)
    
    if [[ $done_count -eq 0 ]]; then
        info "No completed todos to archive"
        return 0
    fi
    
    # Create or update archive file
    if [[ ! -f "$archive_file" ]]; then
        cat > "$archive_file" << EOF
# TODO Archive - $context

Completed todos archived from main TODO.md

EOF
    fi
    
    # Add archive header
    echo -e "\n## Archived on $(get_date)\n" >> "$archive_file"
    
    # Move completed todos to archive
    grep "^- \[x\]" "$todo_file" >> "$archive_file"
    
    # Remove completed todos from main file
    local temp_file="${todo_file}.tmp"
    grep -v "^- \[x\]" "$todo_file" > "$temp_file"
    mv "$temp_file" "$todo_file"
    
    # Update timestamp
    sed -i "s/^Last updated:.*/Last updated: $(get_timestamp)/" "$todo_file"
    
    add_to_history "todo-archive" "$done_count completed todos"
    success "Archived $done_count completed todo(s)"
    echo "Archive saved to: TODO_ARCHIVE.md"
}