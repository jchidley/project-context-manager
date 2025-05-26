#!/bin/bash
# Session-based logging functions for Project Context Manager

# Get the next session number for a context
get_next_session_number() {
    local context="$1"
    local context_dir="${PC_HOME}/${context}"
    local max_session=0
    
    # Find highest session number
    for session_file in "$context_dir"/SESSION_*.md; do
        if [[ -f "$session_file" ]]; then
            local num=$(basename "$session_file" | sed -n 's/SESSION_\([0-9]\+\).*\.md/\1/p')
            if [[ $num -gt $max_session ]]; then
                max_session=$num
            fi
        fi
    done
    
    echo $((max_session + 1))
}

# Create a new session log
create_session_log() {
    local context="$1"
    local title="${2:-Work Session}"
    local context_dir="${PC_HOME}/${context}"
    
    ensure_context_dir "$context"
    
    local session_num=$(get_next_session_number "$context")
    local session_file="SESSION_$(printf "%03d" $session_num)_$(date +%Y%m%d).md"
    local timestamp=$(date '+%Y-%m-%d %H:%M')
    
    {
        echo "# Session $session_num - $title"
        echo "Date: $timestamp"
        echo ""
        echo "## Objective"
        echo "_What are you trying to accomplish?_"
        echo ""
        echo "## Progress"
        echo ""
        echo "## Discoveries"
        echo ""
        echo "## Next Steps"
        echo ""
    } > "$context_dir/$session_file"
    
    echo "$context_dir/$session_file"
}

# Append to current session log
append_to_session() {
    local context="$1"
    local content="$2"
    local context_dir="${PC_HOME}/${context}"
    
    # Find today's session or most recent
    local today=$(date +%Y%m%d)
    local session_file=""
    
    # Look for today's session
    for file in "$context_dir"/SESSION_*_${today}.md; do
        if [[ -f "$file" ]]; then
            session_file="$file"
            break
        fi
    done
    
    # If no today's session, find most recent
    if [[ -z "$session_file" ]]; then
        session_file=$(ls -t "$context_dir"/SESSION_*.md 2>/dev/null | head -1)
    fi
    
    # If still no session, create one
    if [[ -z "$session_file" ]] || [[ ! -f "$session_file" ]]; then
        session_file=$(create_session_log "$context" "Work Session")
    fi
    
    # Append content with timestamp
    {
        echo ""
        echo "### $(date '+%H:%M') - Update"
        echo "$content"
    } >> "$session_file"
    
    echo "Logged to: $(basename "$session_file")"
}

# Generate session summary
generate_session_summary() {
    local context="$1"
    local context_dir="${PC_HOME}/${context}"
    local summary_file="${context_dir}/SESSION_SUMMARY.md"
    
    {
        echo "# Session Summary"
        echo "Generated: $(date '+%Y-%m-%d %H:%M')"
        echo ""
        echo "## Recent Sessions"
        echo ""
        
        # List last 5 sessions
        local count=0
        for session in $(ls -t "$context_dir"/SESSION_*.md 2>/dev/null | head -5); do
            if [[ -f "$session" ]]; then
                local session_name=$(basename "$session" .md)
                local title=$(grep "^# Session" "$session" | head -1 | sed 's/# //')
                local date=$(grep "^Date:" "$session" | cut -d' ' -f2-)
                echo "- **$session_name** - $date"
                
                # Extract objective if exists
                local obj=$(awk '/^## Objective/{getline; getline; if(NF>0) print}' "$session")
                if [[ -n "$obj" ]]; then
                    echo "  - $obj"
                fi
                ((count++))
            fi
        done
        
        echo ""
        echo "## Key Discoveries"
        echo ""
        
        # Extract discoveries from recent sessions
        for session in $(ls -t "$context_dir"/SESSION_*.md 2>/dev/null | head -5); do
            if [[ -f "$session" ]]; then
                awk '/^## Discoveries/{flag=1; next} /^##/{flag=0} flag && NF>0 {print "- " $0}' "$session"
            fi
        done | sort -u | head -10
        
    } > "$summary_file"
    
    echo "Summary updated: $summary_file"
}

# Archive old sessions
archive_old_sessions() {
    local context="$1"
    local days_to_keep="${2:-30}"
    local context_dir="${PC_HOME}/${context}"
    local archive_dir="${context_dir}/.archive"
    
    mkdir -p "$archive_dir"
    
    # Find sessions older than N days
    local archived=0
    find "$context_dir" -maxdepth 1 -name "SESSION_*.md" -mtime +${days_to_keep} -type f | while read -r old_session; do
        mv "$old_session" "$archive_dir/"
        ((archived++))
    done
    
    if [[ $archived -gt 0 ]]; then
        echo "Archived $archived old sessions to $archive_dir"
    fi
}

# Add session log commands to pc
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being run directly, show usage
    echo "Session-based logging functions for Project Context Manager"
    echo ""
    echo "This file provides functions that can be integrated into pc.sh:"
    echo "- create_session_log: Start a new session log"
    echo "- append_to_session: Add updates to current session"
    echo "- generate_session_summary: Create summary of recent sessions"
    echo "- archive_old_sessions: Move old logs to archive"
    echo ""
    echo "To use: source this file in pc.sh and add commands"
fi