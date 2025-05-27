#!/usr/bin/env bash
# lib/stash_commands.sh - Stash management commands for pc

# Command: stash
cmd_stash() {
    local name="${1:-}"
    local current=$(get_current_context)
    
    if [[ -z "$current" ]]; then
        error "No active context to stash"
        return 1
    fi
    
    # Generate name if not provided
    if [[ -z "$name" ]]; then
        name="autostash_$(date +%Y%m%d_%H%M%S)"
    else
        # Sanitize name
        name=$(echo "$name" | tr ' ' '_' | tr -cd '[:alnum:]_.-')
    fi
    
    local stash_path="${STASH_DIR}/${current}_${name}"
    
    # Check if stash already exists
    if [[ -d "$stash_path" ]]; then
        error "Stash already exists: $name"
        return 1
    fi
    
    # Save current files to context
    save_current_context_files "$current"
    
    # Create stash directory
    ensure_dir "$stash_path" || return 1
    
    # Copy context files to stash
    if ! cp -r "${PC_DIR}/${current}/." "$stash_path/"; then
        error "Failed to create stash"
        rm -rf "$stash_path"
        return 1
    fi
    
    # Save metadata
    cat > "${stash_path}/.stash_info" << EOF
Context: $current
Date: $(get_timestamp)
Branch: $(get_git_branch)
Description: $name
User: ${USER}
Host: $(hostname)
EOF

    # Add git status if in repo
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo -e "\nGit Status:" >> "${stash_path}/.stash_info"
        git status --short >> "${stash_path}/.stash_info" 2>/dev/null || true
    fi
    
    add_to_history "stash" "$current as $name"
    success "Created stash: $name"
    
    # Show stash info
    echo -e "${GRAY}Stash location: ${stash_path}${NC}"
}

# Command: stash-pop
cmd_stash_pop() {
    local name="${1:-}"
    local current=$(get_current_context)
    
    if [[ -z "$current" ]]; then
        error "No active context"
        return 1
    fi
    
    # Find matching stash
    local stash_path=""
    
    if [[ -n "$name" ]]; then
        # Look for exact match
        stash_path="${STASH_DIR}/${current}_${name}"
        
        if [[ ! -d "$stash_path" ]]; then
            # Try partial match
            local matches=$(find "$STASH_DIR" -maxdepth 1 -name "${current}_*${name}*" -type d 2>/dev/null)
            local match_count=$(echo "$matches" | grep -c . || echo 0)
            
            if [[ $match_count -eq 0 ]]; then
                error "No stash found matching: $name"
                return 1
            elif [[ $match_count -gt 1 ]]; then
                error "Multiple stashes match: $name"
                echo "Matching stashes:"
                echo "$matches" | while read -r match; do
                    echo "  - $(basename "$match" | sed "s/^${current}_//")"
                done
                return 1
            else
                stash_path="$matches"
            fi
        fi
    else
        # Get most recent stash for current context
        stash_path=$(find "$STASH_DIR" -maxdepth 1 -name "${current}_*" -type d 2>/dev/null | sort -r | head -1)
        
        if [[ -z "$stash_path" ]]; then
            error "No stashes found for context: $current"
            return 1
        fi
    fi
    
    local stash_name=$(basename "$stash_path" | sed "s/^${current}_//")
    
    # Show stash info
    if [[ -f "${stash_path}/.stash_info" ]]; then
        echo -e "${BOLD}Popping stash: $stash_name${NC}"
        grep -E "^(Date|Branch):" "${stash_path}/.stash_info" | sed 's/^/  /'
        echo
    fi
    
    # Create backup before pop
    create_backup "$current"
    
    # Restore stash files
    if ! cp -r "${stash_path}/." "${PC_DIR}/${current}/"; then
        error "Failed to restore stash"
        return 1
    fi
    
    # Remove stash info file from context
    rm -f "${PC_DIR}/${current}/.stash_info"
    
    # Restore files to working directory
    restore_context_files "$current"
    
    # Remove stash
    rm -rf "$stash_path"
    
    add_to_history "stash-pop" "$stash_name for $current"
    success "Popped stash: $stash_name"
    
    # Show what was restored
    echo -e "\n${BOLD}Restored files:${NC}"
    for file in HANDOFF.md TODO.md PROJECT_WISDOM.md; do
        if [[ -f "$file" ]]; then
            echo "  - $file"
        fi
    done
}

# Command: stash-list
cmd_stash_list() {
    if [[ ! -d "$STASH_DIR" ]] || [[ -z "$(ls -A "$STASH_DIR" 2>/dev/null)" ]]; then
        info "No stashes found"
        return 0
    fi
    
    local current=$(get_current_context)
    local total_count=0
    local current_count=0
    
    echo -e "${BOLD}Available stashes:${NC}"
    
    # Group by context
    local contexts=$(find "$STASH_DIR" -maxdepth 1 -type d -name "*_*" -exec basename {} \; | cut -d'_' -f1 | sort -u)
    
    for context in $contexts; do
        local context_stashes=$(find "$STASH_DIR" -maxdepth 1 -name "${context}_*" -type d | sort -r)
        local count=$(echo "$context_stashes" | grep -c . || echo 0)
        
        if [[ $count -gt 0 ]]; then
            # Context header
            if [[ "$context" == "$current" ]]; then
                echo -e "\n${GREEN}$context${NC} (current):"
            else
                echo -e "\n${BLUE}$context${NC}:"
            fi
            
            # List stashes for this context
            echo "$context_stashes" | while read -r stash; do
                if [[ -n "$stash" ]]; then
                    local stash_name=$(basename "$stash" | sed "s/^${context}_//")
                    local info_file="${stash}/.stash_info"
                    
                    echo -n "  - $stash_name"
                    
                    if [[ -f "$info_file" ]]; then
                        local date=$(grep "^Date:" "$info_file" | cut -d' ' -f2- || echo "")
                        local branch=$(grep "^Branch:" "$info_file" | cut -d' ' -f2- || echo "")
                        
                        [[ -n "$date" ]] && echo -n " ${GRAY}($date)${NC}"
                        [[ -n "$branch" ]] && echo -n " ${GRAY}[$branch]${NC}"
                    fi
                    
                    echo
                    
                    ((total_count++))
                    [[ "$context" == "$current" ]] && ((current_count++))
                fi
            done
        fi
    done
    
    # Summary
    echo -e "\n${GRAY}Total: $total_count stash(es)${NC}"
    if [[ -n "$current" ]] && [[ $current_count -gt 0 ]]; then
        echo -e "${GRAY}Current context: $current_count stash(es)${NC}"
    fi
}

# Command: stash-drop
cmd_stash_drop() {
    local name="${1:-}"
    local current=$(get_current_context)
    
    if [[ -z "$name" ]]; then
        error "Stash name required"
        echo "Usage: pc stash-drop <name>"
        return 1
    fi
    
    # If no context, look for stash in any context
    local stash_path=""
    
    if [[ -n "$current" ]]; then
        stash_path="${STASH_DIR}/${current}_${name}"
    fi
    
    if [[ ! -d "$stash_path" ]]; then
        # Try to find in any context
        local matches=$(find "$STASH_DIR" -maxdepth 1 -name "*_${name}" -type d 2>/dev/null)
        local match_count=$(echo "$matches" | grep -c . || echo 0)
        
        if [[ $match_count -eq 0 ]]; then
            # Try partial match
            matches=$(find "$STASH_DIR" -maxdepth 1 -name "*_*${name}*" -type d 2>/dev/null)
            match_count=$(echo "$matches" | grep -c . || echo 0)
            
            if [[ $match_count -eq 0 ]]; then
                error "No stash found matching: $name"
                return 1
            elif [[ $match_count -gt 1 ]]; then
                error "Multiple stashes match: $name"
                echo "Matching stashes:"
                echo "$matches" | while read -r match; do
                    local ctx=$(basename "$match" | cut -d'_' -f1)
                    local stsh=$(basename "$match" | sed "s/^${ctx}_//")
                    echo "  - $ctx: $stsh"
                done
                return 1
            fi
        fi
        
        stash_path="$matches"
    fi
    
    # Get stash info
    local full_name=$(basename "$stash_path")
    local context_name=$(echo "$full_name" | cut -d'_' -f1)
    local stash_name=$(echo "$full_name" | sed "s/^${context_name}_//")
    
    # Confirm deletion
    echo -e "${YELLOW}Warning: This will permanently delete stash '$stash_name' from context '$context_name'${NC}"
    echo -n "Are you sure? [y/N] "
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        info "Deletion cancelled"
        return 0
    fi
    
    # Delete stash
    rm -rf "$stash_path"
    
    add_to_history "stash-drop" "$stash_name from $context_name"
    success "Dropped stash: $stash_name"
}

# Command: stash-show
cmd_stash_show() {
    local name="${1:-}"
    local current=$(get_current_context)
    
    if [[ -z "$name" ]]; then
        error "Stash name required"
        echo "Usage: pc stash-show <name>"
        return 1
    fi
    
    # Find stash
    local stash_path=""
    
    if [[ -n "$current" ]]; then
        stash_path="${STASH_DIR}/${current}_${name}"
    fi
    
    if [[ ! -d "$stash_path" ]]; then
        # Try to find in any context
        local matches=$(find "$STASH_DIR" -maxdepth 1 -name "*_${name}" -o -name "*_*${name}*" -type d 2>/dev/null | head -1)
        
        if [[ -z "$matches" ]]; then
            error "No stash found matching: $name"
            return 1
        fi
        
        stash_path="$matches"
    fi
    
    # Get stash info
    local full_name=$(basename "$stash_path")
    local context_name=$(echo "$full_name" | cut -d'_' -f1)
    local stash_name=$(echo "$full_name" | sed "s/^${context_name}_//")
    
    echo -e "${BOLD}Stash: $stash_name${NC}"
    echo -e "${BOLD}Context: $context_name${NC}"
    
    # Show metadata
    if [[ -f "${stash_path}/.stash_info" ]]; then
        echo -e "\n${BOLD}Metadata:${NC}"
        cat "${stash_path}/.stash_info"
    fi
    
    # Show files
    echo -e "\n${BOLD}Files in stash:${NC}"
    find "$stash_path" -type f -name "*.md" | while read -r file; do
        local basename=$(basename "$file")
        local size=$(get_file_size "$file")
        echo "  - $basename ($(format_size "$size"))"
    done
    
    # Show preview of key files
    for file in HANDOFF.md TODO.md; do
        if [[ -f "${stash_path}/${file}" ]]; then
            echo -e "\n${BOLD}Preview of $file:${NC}"
            head -10 "${stash_path}/${file}" | sed 's/^/  /'
            
            local lines=$(wc -l < "${stash_path}/${file}")
            if [[ $lines -gt 10 ]]; then
                echo "  ... ($((lines - 10)) more lines)"
            fi
        fi
    done
}