#!/bin/bash
# pc v2 - Project Context Manager with Plain Text Storage
# Migrated from SQLite to plain text for better integration with Claude Code

set -euo pipefail

# Configuration
PC_HOME="${HOME}/.project-contexts"
ACTIVE_LINK="${PC_HOME}/.active"
STASH_DIR="${PC_HOME}/.stash"
BACKUP_DIR="${PC_HOME}/.backups"
HISTORY_FILE="${PC_HOME}/.history"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Initialize directory structure
init_pc() {
    mkdir -p "$PC_HOME" "$STASH_DIR" "$BACKUP_DIR"
    touch "$HISTORY_FILE"
}

# Get current context
get_current_context() {
    if [[ -L "$ACTIVE_LINK" ]] && [[ -e "$ACTIVE_LINK" ]]; then
        basename "$(readlink "$ACTIVE_LINK")"
    else
        echo ""
    fi
}

# Ensure context directory exists
ensure_context_dir() {
    local context="$1"
    local context_dir="${PC_HOME}/${context}"
    mkdir -p "$context_dir"
}

# Create a backup before destructive operations
create_backup() {
    local context="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="${BACKUP_DIR}/${context}_${timestamp}"
    
    if [[ -d "${PC_HOME}/${context}" ]]; then
        cp -r "${PC_HOME}/${context}" "$backup_path"
        echo -e "${BLUE}Created backup at: $backup_path${NC}"
    fi
}

# Log command to history
log_command() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $USER | $(pwd) | pc $*" >> "$HISTORY_FILE"
}

# Save context files from working directory
save_context_files() {
    local context_dir="$1"
    
    # Save HANDOFF.md
    if [[ -f "HANDOFF.md" ]]; then
        cp "HANDOFF.md" "$context_dir/"
    fi
    
    # Save PROJECT_WISDOM.md
    if [[ -f "PROJECT_WISDOM.md" ]]; then
        cp "PROJECT_WISDOM.md" "$context_dir/"
    fi
    
    # Save TODO.md
    if [[ -f "TODO.md" ]]; then
        cp "TODO.md" "$context_dir/"
    fi
    
    # Save any session logs
    for log in *_LOG_*.md SESSION_*.md; do
        [[ -f "$log" ]] && cp "$log" "$context_dir/"
    done
}

# Restore context files to working directory
restore_context_files() {
    local context_dir="$1"
    
    # Don't clobber existing files unless --force
    local force=false
    [[ "${2:-}" == "--force" ]] && force=true
    
    for file in HANDOFF.md PROJECT_WISDOM.md TODO.md; do
        if [[ -f "$context_dir/$file" ]]; then
            if [[ -f "$file" ]] && [[ "$force" == "false" ]]; then
                echo -e "${YELLOW}Warning: $file exists in working directory. Use --force to overwrite.${NC}"
            else
                cp "$context_dir/$file" .
                echo -e "${GREEN}Restored $file${NC}"
            fi
        fi
    done
    
    # Restore logs
    for log in "$context_dir"/*_LOG_*.md "$context_dir"/SESSION_*.md; do
        if [[ -f "$log" ]]; then
            local basename=$(basename "$log")
            if [[ -f "$basename" ]] && [[ "$force" == "false" ]]; then
                echo -e "${YELLOW}Warning: $basename exists. Use --force to overwrite.${NC}"
            else
                cp "$log" .
                echo -e "${GREEN}Restored $basename${NC}"
            fi
        fi
    done
}

# Check for uncommitted git changes
check_git_status() {
    if [[ -d ".git" ]]; then
        if ! git diff-index --quiet HEAD 2>/dev/null; then
            echo -e "${YELLOW}Warning: You have uncommitted changes${NC}"
            git status --short
            return 1
        fi
    fi
    return 0
}

# === PLAIN TEXT TODO OPERATIONS ===

# Add a todo item
todo_add() {
    local title="$1"
    local context="${2:-$(get_current_context)}"
    
    if [[ -z "$context" ]]; then
        echo -e "${RED}Error: No active context. Use 'pc switch <context>' first.${NC}"
        return 1
    fi
    
    local context_dir="${PC_HOME}/${context}"
    ensure_context_dir "$context"
    
    local todo_file="${context_dir}/TODO.md"
    local timestamp=$(date '+%Y-%m-%d %H:%M')
    
    # Create TODO.md if it doesn't exist
    if [[ ! -f "$todo_file" ]]; then
        {
            echo "# TODO - $context"
            echo ""
            echo "Last updated: $timestamp"
            echo ""
            echo "## To Do"
            echo ""
        } > "$todo_file"
    fi
    
    # Add the new todo
    # Find the "## To Do" section and add item after it
    if grep -q "^## To Do" "$todo_file"; then
        # Use a temporary file for safe editing
        local tmp_file=$(mktemp)
        local in_todo_section=false
        local added=false
        
        while IFS= read -r line; do
            echo "$line" >> "$tmp_file"
            
            if [[ "$line" == "## To Do" ]]; then
                in_todo_section=true
            elif [[ "$in_todo_section" == true ]] && [[ -z "$line" ]] && [[ "$added" == false ]]; then
                echo "- [ ] $title <!-- created:$timestamp -->" >> "$tmp_file"
                added=true
            elif [[ "$line" =~ ^##\  ]] && [[ "$line" != "## To Do" ]]; then
                in_todo_section=false
            fi
        done < "$todo_file"
        
        # If we didn't add it yet (no blank line after ## To Do), add it at the end of the section
        if [[ "$added" == false ]]; then
            echo "- [ ] $title <!-- created:$timestamp -->" >> "$tmp_file"
        fi
        
        mv "$tmp_file" "$todo_file"
    else
        # No "## To Do" section, append it
        {
            echo ""
            echo "## To Do"
            echo ""
            echo "- [ ] $title <!-- created:$timestamp -->"
        } >> "$todo_file"
    fi
    
    # Update the last updated timestamp
    sed -i "s/^Last updated:.*/Last updated: $timestamp/" "$todo_file"
    
    echo -e "${GREEN}Added todo: $title${NC}"
    
    # If in working directory, update the local TODO.md too
    if [[ -f "TODO.md" ]] && [[ "$(realpath TODO.md)" != "$(realpath "$todo_file")" ]]; then
        cp "$todo_file" "TODO.md"
        echo -e "${BLUE}Updated local TODO.md${NC}"
    fi
}

# List todos
todo_list() {
    local context="${1:-$(get_current_context)}"
    local filter="${2:-all}"  # all, todo, done, in-progress
    
    if [[ -z "$context" ]]; then
        echo -e "${RED}Error: No active context. Use 'pc switch <context>' first.${NC}"
        return 1
    fi
    
    local todo_file="${PC_HOME}/${context}/TODO.md"
    
    if [[ ! -f "$todo_file" ]]; then
        echo -e "${YELLOW}No todos found for context: $context${NC}"
        return 0
    fi
    
    echo -e "${BLUE}=== Todos for $context ===${NC}"
    echo ""
    
    # Parse and display todos
    local current_section=""
    local todo_count=0
    local done_count=0
    local in_progress_count=0
    
    while IFS= read -r line; do
        # Section headers
        if [[ "$line" =~ ^##\  ]]; then
            current_section="$line"
            if [[ "$filter" == "all" ]] || \
               ([[ "$filter" == "todo" ]] && [[ "$line" == "## To Do" ]]) || \
               ([[ "$filter" == "done" ]] && [[ "$line" == "## Completed"* ]]) || \
               ([[ "$filter" == "in-progress" ]] && [[ "$line" == "## In Progress" ]]); then
                echo -e "${PURPLE}$line${NC}"
                echo ""
            fi
        # Todo items
        elif [[ "$line" =~ ^-\ \[\ \]\ (.*) ]]; then
            todo_count=$((todo_count + 1))
            if [[ "$filter" == "all" ]] || [[ "$filter" == "todo" ]]; then
                echo "$line"
            fi
        # In progress items (marked with [>])
        elif [[ "$line" =~ ^-\ \[\>\]\ (.*) ]]; then
            in_progress_count=$((in_progress_count + 1))
            if [[ "$filter" == "all" ]] || [[ "$filter" == "in-progress" ]]; then
                echo -e "${YELLOW}$line${NC}"
            fi
        # Completed items
        elif [[ "$line" =~ ^-\ \[x\]\ (.*) ]]; then
            done_count=$((done_count + 1))
            if [[ "$filter" == "all" ]] || [[ "$filter" == "done" ]]; then
                echo -e "${GREEN}$line${NC}"
            fi
        elif [[ "$filter" == "all" ]] && [[ -n "$line" ]] && [[ ! "$line" =~ ^#\  ]] && [[ ! "$line" =~ ^Last\ updated: ]]; then
            echo "$line"
        fi
    done < "$todo_file"
    
    echo ""
    echo -e "Summary: ${GREEN}$todo_count todo${NC}, ${YELLOW}$in_progress_count in progress${NC}, ${BLUE}$done_count done${NC}"
}

# Mark a todo as complete
todo_complete() {
    local pattern="$1"
    local context="${2:-$(get_current_context)}"
    
    if [[ -z "$context" ]]; then
        echo -e "${RED}Error: No active context. Use 'pc switch <context>' first.${NC}"
        return 1
    fi
    
    local todo_file="${PC_HOME}/${context}/TODO.md"
    
    if [[ ! -f "$todo_file" ]]; then
        echo -e "${RED}No todos found for context: $context${NC}"
        return 1
    fi
    
    # Find and mark the todo as complete
    local tmp_file=$(mktemp)
    local found=false
    local completed_text=""
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^-\ \[\ \]\ (.*)$pattern(.*) ]] || [[ "$line" =~ ^-\ \[\>\]\ (.*)$pattern(.*) ]]; then
            # Extract the todo text without the checkbox
            local todo_text="${BASH_REMATCH[1]}$pattern${BASH_REMATCH[2]}"
            completed_text="$todo_text"
            
            # Mark as complete with timestamp
            line="- [x] $todo_text <!-- completed:$(date '+%Y-%m-%d %H:%M') -->"
            found=true
            echo -e "${GREEN}Completed: $completed_text${NC}"
        fi
        echo "$line" >> "$tmp_file"
    done < "$todo_file"
    
    if [[ "$found" == false ]]; then
        echo -e "${RED}No matching todo found for pattern: $pattern${NC}"
        rm "$tmp_file"
        return 1
    fi
    
    # Update the file
    mv "$tmp_file" "$todo_file"
    
    # Update last modified
    sed -i "s/^Last updated:.*/Last updated: $(date '+%Y-%m-%d %H:%M')/" "$todo_file"
    
    # If in working directory, update the local TODO.md too
    if [[ -f "TODO.md" ]] && [[ "$(realpath TODO.md)" != "$(realpath "$todo_file")" ]]; then
        cp "$todo_file" "TODO.md"
        echo -e "${BLUE}Updated local TODO.md${NC}"
    fi
}

# === GIT-STYLE OPERATIONS ===

# Stash current context
cmd_stash() {
    local current=$(get_current_context)
    
    if [[ -z "$current" ]]; then
        echo -e "${RED}No active context to stash${NC}"
        return 1
    fi
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local stash_name="${current}_${timestamp}"
    local stash_path="${STASH_DIR}/${stash_name}"
    
    mkdir -p "$stash_path"
    
    # Save all markdown files
    local saved_count=0
    for file in HANDOFF.md PROJECT_WISDOM*.md TODO.md *_LOG*.md SESSION_*.md; do
        if [[ -f "$file" ]]; then
            cp "$file" "$stash_path/"
            saved_count=$((saved_count + 1))
        fi
    done
    
    # Save git info if in repo
    if [[ -d ".git" ]]; then
        git branch --show-current > "$stash_path/.git_branch" 2>/dev/null || true
        git rev-parse HEAD > "$stash_path/.git_commit" 2>/dev/null || true
    fi
    
    # Create stash info
    {
        echo "Context: $current"
        echo "Created: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Directory: $(pwd)"
        echo "Files: $saved_count"
    } > "$stash_path/.stash_info"
    
    echo -e "${GREEN}Created stash: $stash_name${NC}"
    echo "Saved $saved_count files"
}

# Pop most recent stash
cmd_stash_pop() {
    # Find most recent stash
    local latest_stash=""
    local latest_time=0
    
    for stash_dir in "$STASH_DIR"/*; do
        if [[ -d "$stash_dir" ]]; then
            local mtime=$(stat -f%m "$stash_dir" 2>/dev/null || stat -c%Y "$stash_dir" 2>/dev/null)
            if [[ $mtime -gt $latest_time ]]; then
                latest_time=$mtime
                latest_stash="$stash_dir"
            fi
        fi
    done
    
    if [[ -z "$latest_stash" ]]; then
        echo -e "${RED}No stashes found${NC}"
        return 1
    fi
    
    local stash_name=$(basename "$latest_stash")
    echo -e "${BLUE}Restoring stash: $stash_name${NC}"
    
    # Show stash info
    if [[ -f "$latest_stash/.stash_info" ]]; then
        cat "$latest_stash/.stash_info"
        echo ""
    fi
    
    # Restore files
    local restored_count=0
    for file in "$latest_stash"/*.md; do
        if [[ -f "$file" ]]; then
            local basename=$(basename "$file")
            cp "$file" .
            echo -e "${GREEN}Restored $basename${NC}"
            restored_count=$((restored_count + 1))
        fi
    done
    
    # Clean up stash
    rm -rf "$latest_stash"
    echo -e "${GREEN}Popped stash: $stash_name (restored $restored_count files)${NC}"
}

# List stashes
cmd_stash_list() {
    echo -e "${BLUE}Available stashes:${NC}"
    
    local stash_count=0
    for stash_dir in "$STASH_DIR"/*; do
        if [[ -d "$stash_dir" ]]; then
            local stash_name=$(basename "$stash_dir")
            
            # Read stash info
            if [[ -f "$stash_dir/.stash_info" ]]; then
                local created=$(grep "Created:" "$stash_dir/.stash_info" | cut -d' ' -f2-)
                local files=$(grep "Files:" "$stash_dir/.stash_info" | cut -d' ' -f2)
                echo "  $stash_name - $created ($files files)"
            else
                echo "  $stash_name"
            fi
            stash_count=$((stash_count + 1))
        fi
    done
    
    if [[ $stash_count -eq 0 ]]; then
        echo "  (no stashes)"
    fi
}

# Diff with another context
cmd_diff() {
    local other_context="$1"
    local current=$(get_current_context)
    
    if [[ -z "$current" ]]; then
        echo -e "${RED}No active context${NC}"
        return 1
    fi
    
    if [[ -z "$other_context" ]]; then
        echo -e "${RED}Usage: pc diff <other-context>${NC}"
        return 1
    fi
    
    if [[ ! -d "${PC_HOME}/${other_context}" ]]; then
        echo -e "${RED}Context not found: $other_context${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Comparing $current with $other_context${NC}"
    echo ""
    
    # Compare key files
    for file in HANDOFF.md PROJECT_WISDOM.md TODO.md; do
        local current_file="${PC_HOME}/${current}/$file"
        local other_file="${PC_HOME}/${other_context}/$file"
        
        if [[ -f "$current_file" ]] || [[ -f "$other_file" ]]; then
            echo -e "${PURPLE}=== $file ===${NC}"
            
            if [[ ! -f "$current_file" ]]; then
                echo -e "${YELLOW}Only in $other_context${NC}"
            elif [[ ! -f "$other_file" ]]; then
                echo -e "${YELLOW}Only in $current${NC}"
            else
                # Show diff
                diff -u "$other_file" "$current_file" | sed '1,2d' || true
            fi
            echo ""
        fi
    done
}

# === CONTEXT OPERATIONS ===

# Switch context
cmd_switch() {
    local new_context="$1"
    local current=$(get_current_context)
    
    if [[ "$new_context" == "$current" ]]; then
        echo -e "${YELLOW}Already in context: $new_context${NC}"
        return 0
    fi
    
    # Check git status unless --force
    if [[ "${2:-}" != "--force" ]]; then
        check_git_status || {
            echo -e "${RED}Commit or stash changes before switching context${NC}"
            echo "Use 'pc switch $new_context --force' to switch anyway"
            return 1
        }
    fi
    
    # Save current context if exists
    if [[ -n "$current" ]]; then
        local current_dir="${PC_HOME}/${current}"
        ensure_context_dir "$current"
        save_context_files "$current_dir"
        echo -e "${GREEN}Saved context: $current${NC}"
    fi
    
    # Create new context if needed
    ensure_context_dir "$new_context"
    
    # Update active link
    ln -sfn "${PC_HOME}/${new_context}" "$ACTIVE_LINK"
    
    # Restore new context files
    restore_context_files "${PC_HOME}/${new_context}"
    
    echo -e "${GREEN}Switched to context: $new_context${NC}"
    
    # Show todo summary for new context
    echo ""
    todo_list "$new_context" | head -5
}

# Show status
cmd_status() {
    local current=$(get_current_context)
    
    if [[ -z "$current" ]]; then
        echo -e "${YELLOW}No active context${NC}"
        echo "Use 'pc switch <context>' to activate a context"
        return 0
    fi
    
    echo -e "${BLUE}Current context: ${GREEN}$current${NC}"
    echo ""
    
    # Show git status if in repo
    if [[ -d ".git" ]]; then
        echo -e "${PURPLE}Git status:${NC}"
        git status --short || true
        echo ""
    fi
    
    # Show todos
    todo_list "$current" | head -10
    
    # Show recent files
    echo ""
    echo -e "${PURPLE}Context files:${NC}"
    local context_dir="${PC_HOME}/${current}"
    for file in HANDOFF.md PROJECT_WISDOM.md TODO.md; do
        if [[ -f "$context_dir/$file" ]]; then
            local size=$(stat -f%z "$context_dir/$file" 2>/dev/null || stat -c%s "$context_dir/$file" 2>/dev/null || echo "?")
            local modified=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$context_dir/$file" 2>/dev/null || stat -c "%y" "$context_dir/$file" 2>/dev/null | cut -d' ' -f1,2 || echo "?")
            printf "  %-20s %8s  %s\n" "$file" "$size" "$modified"
        fi
    done
}

# List all contexts
cmd_list() {
    echo -e "${BLUE}Available contexts:${NC}"
    local current=$(get_current_context)
    
    for context_path in "$PC_HOME"/*/; do
        if [[ -d "$context_path" ]] && [[ ! "$context_path" =~ \.stash|\.backups|\.wiki|\.templates ]]; then
            local context=$(basename "$context_path")
            local marker=""
            [[ "$context" == "$current" ]] && marker=" ${GREEN}(active)${NC}"
            
            # Count todos
            local todo_file="$context_path/TODO.md"
            if [[ -f "$todo_file" ]]; then
                local todo_count=$(grep -c "^- \[ \]" "$todo_file" 2>/dev/null || echo 0)
                local done_count=$(grep -c "^- \[x\]" "$todo_file" 2>/dev/null || echo 0)
                echo -e "  $context$marker - ${todo_count} todos, ${done_count} done"
            else
                echo -e "  $context$marker"
            fi
        fi
    done
}

# Show help
cmd_help() {
    cat << EOF
${BLUE}pc v2 - Project Context Manager${NC}
${GREEN}Now with plain text storage for Claude Code integration!${NC}

${PURPLE}Usage:${NC}
  pc <command> [arguments]

${PURPLE}Context Commands:${NC}
  switch <name>     Switch to a different context
  status           Show current context status
  list             List all contexts
  save             Save current work files to context
  restore          Restore context files to working directory
  
${PURPLE}Todo Commands:${NC}
  todo add <text>              Add a new todo
  todo list [filter]           List todos (filter: all|todo|done)
  todo complete <pattern>      Mark todo as complete
  
${PURPLE}Git-style Commands:${NC}
  stash            Temporarily save current context
  stash pop        Restore most recent stash
  diff <context>   Compare with another context
  log              Show context history
  
${PURPLE}Examples:${NC}
  pc switch my-project         Switch to my-project context
  pc todo add "Fix bug #123"   Add a todo item
  pc todo complete "bug"       Mark matching todo as done
  pc status                    Show current status
  
${PURPLE}Files Managed:${NC}
  - HANDOFF.md          Work session state
  - PROJECT_WISDOM.md   Accumulated knowledge
  - TODO.md            Task list (plain text)
  - *_LOG_*.md         Session logs

${PURPLE}Storage:${NC}
  ~/.project-contexts/<context-name>/
  Plain text files for easy editing and LLM access
EOF
}

# Main command dispatcher
main() {
    init_pc
    log_command "$@"
    
    local cmd="${1:-help}"
    shift || true
    
    case "$cmd" in
        # Context commands
        switch|sw)
            cmd_switch "$@"
            ;;
        status|st)
            cmd_status "$@"
            ;;
        list|ls)
            cmd_list "$@"
            ;;
        save)
            local current=$(get_current_context)
            if [[ -n "$current" ]]; then
                save_context_files "${PC_HOME}/${current}"
                echo -e "${GREEN}Saved current context files${NC}"
            else
                echo -e "${RED}No active context${NC}"
            fi
            ;;
        restore)
            local current=$(get_current_context)
            if [[ -n "$current" ]]; then
                restore_context_files "${PC_HOME}/${current}" "$@"
            else
                echo -e "${RED}No active context${NC}"
            fi
            ;;
            
        # Todo commands
        todo)
            local subcmd="${1:-list}"
            shift || true
            case "$subcmd" in
                add|a)
                    todo_add "$@"
                    ;;
                list|ls|l)
                    todo_list "$@"
                    ;;
                complete|done|d)
                    todo_complete "$@"
                    ;;
                *)
                    echo -e "${RED}Unknown todo command: $subcmd${NC}"
                    echo "Use: todo add|list|complete"
                    ;;
            esac
            ;;
            
        # Git-style commands
        stash)
            local subcmd="${1:-save}"
            shift || true
            case "$subcmd" in
                save|"")
                    cmd_stash
                    ;;
                pop)
                    cmd_stash_pop
                    ;;
                list|ls)
                    cmd_stash_list
                    ;;
                *)
                    echo -e "${RED}Unknown stash command: $subcmd${NC}"
                    echo "Use: stash [save|pop|list]"
                    ;;
            esac
            ;;
        diff)
            cmd_diff "$@"
            ;;
        log)
            echo "Recent context operations:"
            tail -20 "$HISTORY_FILE" | grep -E "switch|save|restore|todo"
            ;;
            
        # Help
        help|--help|-h)
            cmd_help
            ;;
            
        *)
            echo -e "${RED}Unknown command: $cmd${NC}"
            cmd_help
            return 1
            ;;
    esac
}

# Run main if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi