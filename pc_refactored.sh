#!/usr/bin/env bash
# pc_refactored.sh - Project Context Manager using common library
# Refactored version with better error handling and modular structure

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common library
source "${SCRIPT_DIR}/lib/common.sh"

# Set up error handling
setup_error_handling

# Version
readonly VERSION="0.2.2"

# Session log functions
source "${SCRIPT_DIR}/session_log.sh" 2>/dev/null || true

# Usage information
usage() {
    cat << EOF
Project Context Manager v${VERSION}

Usage: pc <command> [arguments]

Commands:
    init <name>          Initialize a new context
    switch <name>        Switch to a different context
    status               Show current context status
    list                 List all contexts
    delete <name>        Delete a context
    rename <old> <new>   Rename a context
    
    todo <subcommand>    Manage todos (add, complete, list, etc.)
    stash [name]         Stash current context
    stash-pop [name]     Restore stashed context
    stash-list           List all stashes
    
    diff [context]       Compare current state with saved context
    log                  Show recent activity
    
    session-start        Start a new session log
    session-end [summary] End current session with summary
    session-current      Show current session log
    
    help                 Show this help message

Todo Subcommands:
    add <text>           Add a new todo
    complete <pattern>   Mark todo as complete
    list                 List all todos
    progress             Show categorized progress
    search <pattern>     Search todos

Environment Variables:
    PC_HOME              Override default ~/.project-contexts
    DEBUG                Set to 1 for debug output

Examples:
    pc init my-project
    pc todo add "Implement user authentication"
    pc switch other-project
    pc stash "work in progress"
EOF
}

# Command: init
cmd_init() {
    local context="${1:-}"
    
    if [[ -z "$context" ]]; then
        error "Context name required"
        echo "Usage: pc init <name>"
        return 1
    fi
    
    validate_context_name "$context" || return 1
    
    local context_dir="${PC_DIR}/${context}"
    
    if [[ -d "$context_dir" ]]; then
        error "Context already exists: $context"
        return 1
    fi
    
    info "Initializing context: $context"
    
    ensure_dir "$context_dir" || return 1
    set_current_context "$context" || return 1
    
    # Create default files
    cat > "${context_dir}/HANDOFF.md" << EOF
# Project: $context
Updated: $(get_timestamp)

## Current State
Status: New project initialized

## Essential Context
- Project initialized with pc

## Next Step
Define project goals and initial tasks

## If Blocked
Review project requirements

## Related Documents
- TODO.md - Task tracking
- PROJECT_WISDOM.md - Technical insights
EOF

    cat > "${context_dir}/TODO.md" << EOF
# TODO - $context

Last updated: $(get_timestamp)

## To Do

- [ ] Define project goals <!-- created:$(get_date) -->
- [ ] Set up development environment <!-- created:$(get_date) -->
- [ ] Create initial project structure <!-- created:$(get_date) -->

## In Progress

## Done
EOF

    touch "${context_dir}/PROJECT_WISDOM.md"
    
    add_to_history "init" "$context"
    success "Initialized context: $context"
}

# Command: switch
cmd_switch() {
    local new_context="${1:-}"
    
    if [[ -z "$new_context" ]]; then
        error "Context name required"
        echo "Usage: pc switch <name>"
        return 1
    fi
    
    validate_context_name "$new_context" || return 1
    
    local new_context_dir="${PC_DIR}/${new_context}"
    
    if [[ ! -d "$new_context_dir" ]]; then
        error "Context does not exist: $new_context"
        echo "Available contexts:"
        cmd_list
        return 1
    fi
    
    # Check for uncommitted changes
    check_git_status false || return 1
    
    # Save current context state
    local current
    current=$(get_current_context)
    if [[ -n "$current" ]] && [[ "$current" != "$new_context" ]]; then
        debug "Saving current context: $current"
        save_current_context_files "$current"
    fi
    
    # Restore new context
    restore_context_files "$new_context"
    
    # Update active link
    set_current_context "$new_context" || return 1
    
    add_to_history "switch" "$new_context"
    success "Switched to context: $new_context"
    
    # Show status
    cmd_status
}

# Command: status
cmd_status() {
    local current
    current=$(get_current_context)
    
    if [[ -z "$current" ]]; then
        info "No active context"
        echo "Use 'pc init <name>' to create a new context"
        echo "Use 'pc list' to see available contexts"
        return 0
    fi
    
    echo -e "${BOLD}Active context:${NC} ${GREEN}$current${NC}"
    
    local context_dir="${PC_DIR}/${current}"
    
    # Git information
    local git_branch
        git_branch=$(get_git_branch)
    if [[ -n "$git_branch" ]]; then
        echo -e "${BOLD}Git branch:${NC} $git_branch"
    fi
    
    # Current state from HANDOFF.md
    if [[ -f "${context_dir}/HANDOFF.md" ]]; then
        echo -e "\n${BOLD}Current state:${NC}"
        grep -A2 "^## Current State" "${context_dir}/HANDOFF.md" 2>/dev/null | tail -n +2 | sed 's/^/  /' || true
    fi
    
    # Active todos
    if [[ -f "${context_dir}/TODO.md" ]]; then
        local active_count
        active_count=$(grep -c "^- \[ \]" "${context_dir}/TODO.md" 2>/dev/null || echo 0)
        local done_count
        done_count=$(grep -c "^- \[x\]" "${context_dir}/TODO.md" 2>/dev/null || echo 0)
        
        echo -e "\n${BOLD}Todos:${NC} $active_count active, $done_count completed"
        
        if [[ $active_count -gt 0 ]]; then
        echo -e "${BOLD}Recent todos:${NC}"
        grep "^- \[ \]" "${context_dir}/TODO.md" 2>/dev/null | head -3 | sed 's/^/  /' || true
        if [[ $active_count -gt 3 ]]; then
            echo "  ... and $((active_count - 3)) more"
        fi
        fi
    fi
    
    # Session information
    if command_exists session_current 2>/dev/null; then
        local session_info
        session_info=$(session_current 2>/dev/null || true)
        if [[ -n "$session_info" ]]; then
        echo -e "\n${BOLD}Current session:${NC}"
        echo "  $session_info"
        fi
    fi
}

# Command: list
cmd_list() {
    if [[ ! -d "$PC_DIR" ]]; then
        info "No contexts found"
        echo "Use 'pc init <name>' to create your first context"
        return 0
    fi
    
    local current
    current=$(get_current_context)
    local count=0
    
    echo -e "${BOLD}Available contexts:${NC}"
    
    for dir in "$PC_DIR"/*; do
        if [[ -d "$dir" ]] && [[ ! "$(basename "$dir")" =~ ^\. ]]; then
        local name
        name=$(basename "$dir")
        local todos=""
        local handoff_status=""
        
        # Count todos
        if [[ -f "$dir/TODO.md" ]]; then
            local active
        active=$(grep -c "^- \[ \]" "$dir/TODO.md" 2>/dev/null || echo 0)
            if [[ $active -gt 0 ]]; then
                todos=" ${GRAY}($active todos)${NC}"
            fi
        fi
        
        # Get status from HANDOFF.md
        if [[ -f "$dir/HANDOFF.md" ]]; then
            handoff_status=$(grep -A1 "^Status:" "$dir/HANDOFF.md" 2>/dev/null | tail -1 | sed 's/^[[:space:]]*//' || true)
            if [[ -n "$handoff_status" ]] && [[ "$handoff_status" != "Status:"* ]]; then
                handoff_status=" - ${GRAY}${handoff_status}${NC}"
            else
                handoff_status=""
            fi
        fi
        
        if [[ "$name" == "$current" ]]; then
            echo -e "  ${GREEN}* $name${NC}${todos}${handoff_status}"
        else
            echo -e "    $name${todos}${handoff_status}"
        fi
        ((count++))
        fi
    done
    
    if [[ $count -eq 0 ]]; then
        info "No contexts found"
        echo "Use 'pc init <name>' to create your first context"
    fi
}

# Command: delete
cmd_delete() {
    local context="${1:-}"
    
    if [[ -z "$context" ]]; then
        error "Context name required"
        echo "Usage: pc delete <name>"
        return 1
    fi
    
    local context_dir="${PC_DIR}/${context}"
    
    if [[ ! -d "$context_dir" ]]; then
        error "Context does not exist: $context"
        return 1
    fi
    
    local current
    current=$(get_current_context)
    if [[ "$context" == "$current" ]]; then
        error "Cannot delete active context"
        echo "Switch to another context first"
        return 1
    fi
    
    # Confirm deletion
    echo -e "${YELLOW}Warning: This will permanently delete context '$context'${NC}"
    echo -n "Are you sure? [y/N] "
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        info "Deletion cancelled"
        return 0
    fi
    
    # Create backup before deletion
    create_backup "$context"
    
    # Delete context
    rm -rf "$context_dir"
    add_to_history "delete" "$context"
    
    success "Deleted context: $context"
}

# Command: rename
cmd_rename() {
    local old_name="${1:-}"
    local new_name="${2:-}"
    
    if [[ -z "$old_name" ]] || [[ -z "$new_name" ]]; then
        error "Both old and new names required"
        echo "Usage: pc rename <old> <new>"
        return 1
    fi
    
    validate_context_name "$new_name" || return 1
    
    local old_dir="${PC_DIR}/${old_name}"
    local new_dir="${PC_DIR}/${new_name}"
    
    if [[ ! -d "$old_dir" ]]; then
        error "Context does not exist: $old_name"
        return 1
    fi
    
    if [[ -d "$new_dir" ]]; then
        error "Context already exists: $new_name"
        return 1
    fi
    
    # Rename directory
    mv "$old_dir" "$new_dir"
    
    # Update active link if needed
    local current
    current=$(get_current_context)
    if [[ "$current" == "$old_name" ]]; then
        set_current_context "$new_name"
    fi
    
    add_to_history "rename" "$old_name -> $new_name"
    success "Renamed context: $old_name -> $new_name"
}

# Save current context files to storage
save_current_context_files() {
    local context="${1:-$(get_current_context)}"
    if [[ -z "$context" ]]; then
        return 0
    fi
    
    local context_dir="${PC_DIR}/${context}"
    ensure_dir "$context_dir"
    
    # Save project files if they exist in current directory
    for file in HANDOFF.md TODO.md PROJECT_WISDOM.md; do
        if [[ -f "$file" ]]; then
        debug "Saving $file to context"
        safe_copy "$file" "${context_dir}/${file}" false
        fi
    done
}

# Restore context files from storage
restore_context_files() {
    local context="${1:-}"
    if [[ -z "$context" ]]; then
        return 1
    fi
    
    local context_dir="${PC_DIR}/${context}"
    if [[ ! -d "$context_dir" ]]; then
        return 1
    fi
    
    # Restore project files
    for file in HANDOFF.md TODO.md PROJECT_WISDOM.md; do
        if [[ -f "${context_dir}/${file}" ]]; then
        debug "Restoring $file from context"
        safe_copy "${context_dir}/${file}" "$file" false
        fi
    done
}

# Include todo commands
source "${SCRIPT_DIR}/lib/todo_commands.sh" 2>/dev/null || {
    # Fallback todo commands if separate file doesn't exist
    cmd_todo() {
        local subcommand="${1:-list}"
        shift || true
        
        case "$subcommand" in
        add|complete|list|progress|search)
            todo_"$subcommand" "$@"
            ;;
        *)
            error "Unknown todo subcommand: $subcommand"
            echo "Available subcommands: add, complete, list, progress, search"
            return 1
            ;;
        esac
    }
    
    todo_add() {
        local context
        context=$(get_current_context)
        if [[ -z "$context" ]]; then
        error "No active context"
        return 1
        fi
        
        local text="$*"
        if [[ -z "$text" ]]; then
        error "Todo text required"
        return 1
        fi
        
        local todo_file="${PC_DIR}/${context}/TODO.md"
        local date
        date=$(get_date)
        
        # Add to appropriate section
        if grep -q "^## To Do" "$todo_file" 2>/dev/null; then
        # Insert after "## To Do" header
        sed -i "/^## To Do/a\\\\n- [ ] $text <!-- created:$date -->" "$todo_file"
        else
        # Append to file
        echo -e "\n- [ ] $text <!-- created:$date -->" >> "$todo_file"
        fi
        
        success "Added todo: $text"
    }
    
    todo_complete() {
        local context
        context=$(get_current_context)
        if [[ -z "$context" ]]; then
        error "No active context"
        return 1
        fi
        
        local pattern="$*"
        if [[ -z "$pattern" ]]; then
        error "Search pattern required"
        return 1
        fi
        
        local todo_file="${PC_DIR}/${context}/TODO.md"
        local escaped_pattern
        escaped_pattern=$(escape_regex "$pattern")
        local date
        date=$(get_date)
        
        # Find and complete matching todo
        if grep -q "^- \[ \] .*${pattern}" "$todo_file" 2>/dev/null; then
        sed -i "s/^- \[ \] \(.*${escaped_pattern}.*\)$/- [x] \1 <!-- completed:$date -->/" "$todo_file"
        success "Completed todo matching: $pattern"
        else
        error "No uncompleted todo found matching: $pattern"
        return 1
        fi
    }
    
    todo_list() {
        local context
        context=$(get_current_context)
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
    
    todo_progress() {
        local context
        context=$(get_current_context)
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
        
        # Show each section
        for section in "To Do" "In Progress" "Done"; do
        if grep -q "^## $section" "$todo_file" 2>/dev/null; then
            echo -e "${BLUE}## $section${NC}"
            sed -n "/^## $section/,/^##/{/^##/!p}" "$todo_file" | grep "^- \[" | head -10 || true
            
            local count
        count=$(sed -n "/^## $section/,/^##/{/^##/!p}" "$todo_file" | grep -c "^- \[" || echo 0)
            if [[ $count -gt 10 ]]; then
                echo "  ... and $((count - 10)) more"
            fi
            echo
        fi
        done
    }
    
    todo_search() {
        local context
        context=$(get_current_context)
        if [[ -z "$context" ]]; then
        error "No active context"
        return 1
        fi
        
        local pattern="$*"
        if [[ -z "$pattern" ]]; then
        error "Search pattern required"
        return 1
        fi
        
        local todo_file="${PC_DIR}/${context}/TODO.md"
        
        if [[ ! -f "$todo_file" ]]; then
        info "No todos found"
        return 0
        fi
        
        echo -e "${BOLD}Searching todos for: $pattern${NC}\n"
        grep -i "$pattern" "$todo_file" | grep "^- \[" || {
        info "No todos found matching: $pattern"
        }
    }
}

# Include stash commands
source "${SCRIPT_DIR}/lib/stash_commands.sh" 2>/dev/null || {
    # Fallback stash commands
    cmd_stash() {
        local name="${1:-autostash_$(date +%Y%m%d_%H%M%S)}"
        local current
    current=$(get_current_context)
        
        if [[ -z "$current" ]]; then
        error "No active context to stash"
        return 1
        fi
        
        local stash_path="${STASH_DIR}/${current}_${name}"
        
        # Save current files
        save_current_context_files "$current"
        
        # Create stash
        ensure_dir "$stash_path"
        cp -r "${PC_DIR}/${current}/." "$stash_path/"
        
        # Save metadata
        cat > "${stash_path}/.stash_info" << EOF
Context: $current
Date: $(get_timestamp)
Branch: $(get_git_branch)
Description: $name
EOF
        
        add_to_history "stash" "$current as $name"
        success "Stashed context: $current as $name"
    }
    
    cmd_stash_pop() {
        local name="${1:-}"
        local current
    current=$(get_current_context)
        
        if [[ -z "$current" ]]; then
        error "No active context"
        return 1
        fi
        
        # Find matching stash
        local stash_path=""
        if [[ -n "$name" ]]; then
        stash_path="${STASH_DIR}/${current}_${name}"
        else
        # Get most recent stash for current context
        stash_path=$(find "$STASH_DIR" -maxdepth 1 -name "${current}_*" -type d | sort -r | head -1)
        fi
        
        if [[ -z "$stash_path" ]] || [[ ! -d "$stash_path" ]]; then
        error "No stash found"
        return 1
        fi
        
        # Create backup before pop
        create_backup "$current"
        
        # Restore stash
        cp -r "${stash_path}/." "${PC_DIR}/${current}/"
        restore_context_files "$current"
        
        # Remove stash
        rm -rf "$stash_path"
        
        local stash_name
        stash_name=$(basename "$stash_path" | sed "s/^${current}_//")
        add_to_history "stash-pop" "$stash_name for $current"
        success "Popped stash: $stash_name"
    }
    
    cmd_stash_list() {
        if [[ ! -d "$STASH_DIR" ]] || [[ -z "$(ls -A "$STASH_DIR" 2>/dev/null)" ]]; then
        info "No stashes found"
        return 0
        fi
        
        echo -e "${BOLD}Available stashes:${NC}"
        
        for stash in "$STASH_DIR"/*; do
        if [[ -d "$stash" ]]; then
            local stash_name
        stash_name=$(basename "$stash")
            local info_file="${stash}/.stash_info"
            
            if [[ -f "$info_file" ]]; then
                local context
        context=$(grep "^Context:" "$info_file" | cut -d' ' -f2-)
                local date
        date=$(grep "^Date:" "$info_file" | cut -d' ' -f2-)
                local branch
        branch=$(grep "^Branch:" "$info_file" | cut -d' ' -f2- || echo "")
                
                echo -e "\n  ${GREEN}$stash_name${NC}"
                echo "    Context: $context"
                echo "    Date: $date"
                [[ -n "$branch" ]] && echo "    Branch: $branch"
            else
                echo -e "\n  $stash_name (no metadata)"
            fi
        fi
        done
    }
}

# Command: diff
cmd_diff() {
    local other_context="${1:-}"
    local current
    current=$(get_current_context)
    
    if [[ -z "$current" ]]; then
        error "No active context"
        return 1
    fi
    
    # Save current state
    save_current_context_files "$current"
    
    if [[ -z "$other_context" ]]; then
        # Compare working directory with saved context
        echo -e "${BOLD}Comparing working directory with saved context: $current${NC}\n"
        
        for file in HANDOFF.md TODO.md PROJECT_WISDOM.md; do
        if [[ -f "$file" ]] || [[ -f "${PC_DIR}/${current}/${file}" ]]; then
            echo -e "${BLUE}=== $file ===${NC}"
            
            if [[ ! -f "$file" ]]; then
                echo "File only exists in saved context"
            elif [[ ! -f "${PC_DIR}/${current}/${file}" ]]; then
                echo "File only exists in working directory"
            else
                diff -u "${PC_DIR}/${current}/${file}" "$file" || true
            fi
            echo
        fi
        done
    else
        # Compare two contexts
        if [[ ! -d "${PC_DIR}/${other_context}" ]]; then
        error "Context does not exist: $other_context"
        return 1
        fi
        
        echo -e "${BOLD}Comparing contexts: $current vs $other_context${NC}\n"
        
        for file in HANDOFF.md TODO.md PROJECT_WISDOM.md; do
        local file1="${PC_DIR}/${current}/${file}"
        local file2="${PC_DIR}/${other_context}/${file}"
        
        if [[ -f "$file1" ]] || [[ -f "$file2" ]]; then
            echo -e "${BLUE}=== $file ===${NC}"
            
            if [[ ! -f "$file1" ]]; then
                echo "File only exists in $other_context"
            elif [[ ! -f "$file2" ]]; then
                echo "File only exists in $current"
            else
                diff -u "$file1" "$file2" || true
            fi
            echo
        fi
        done
    fi
}

# Command: log
cmd_log() {
    local limit="${1:-20}"
    
    if [[ ! -f "$HISTORY_FILE" ]]; then
        info "No history found"
        return 0
    fi
    
    echo -e "${BOLD}Recent activity:${NC}\n"
    
    tail -n "$limit" "$HISTORY_FILE" | while IFS= read -r line; do
        # Parse timestamp and action
        if [[ "$line" =~ ^\[([^\]]+)\][[:space:]](.+)$ ]]; then
        local timestamp="${BASH_REMATCH[1]}"
        local action="${BASH_REMATCH[2]}"
        
        # Color code based on action
        case "$action" in
            init*)     echo -e "${GREEN}[$timestamp]${NC} $action" ;;
            switch*)   echo -e "${BLUE}[$timestamp]${NC} $action" ;;
            delete*)   echo -e "${RED}[$timestamp]${NC} $action" ;;
            stash*)    echo -e "${YELLOW}[$timestamp]${NC} $action" ;;
            *)         echo -e "${GRAY}[$timestamp]${NC} $action" ;;
        esac
        else
        echo "$line"
        fi
    done
}

# Main command dispatcher
main() {
    # Initialize if needed
    init_pc_structure
    
    local cmd="${1:-status}"
    shift || true
    
    case "$cmd" in
        init|new)
        cmd_init "$@"
        ;;
        switch|sw)
        cmd_switch "$@"
        ;;
        status|st)
        cmd_status "$@"
        ;;
        list|ls)
        cmd_list "$@"
        ;;
        delete|rm)
        cmd_delete "$@"
        ;;
        rename|mv)
        cmd_rename "$@"
        ;;
        todo)
        cmd_todo "$@"
        ;;
        stash)
        cmd_stash "$@"
        ;;
        stash-pop|pop)
        cmd_stash_pop "$@"
        ;;
        stash-list|stashes)
        cmd_stash_list "$@"
        ;;
        diff)
        cmd_diff "$@"
        ;;
        log|history)
        cmd_log "$@"
        ;;
        session-start)
        session_start "$@"
        ;;
        session-end)
        session_end "$@"
        ;;
        session-current)
        session_current "$@"
        ;;
        help|--help|-h)
        usage
        ;;
        version|--version|-v)
        echo "Project Context Manager v${VERSION}"
        ;;
        *)
        error "Unknown command: $cmd"
        echo "Use 'pc help' for usage information"
        exit 1
        ;;
    esac
}

# Run main function
main "$@"