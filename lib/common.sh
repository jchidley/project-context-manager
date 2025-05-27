#!/usr/bin/env bash
# lib/common.sh - Common functions for project-context-manager
# Shared utilities to reduce code duplication across pc scripts

set -euo pipefail

# Color definitions - check if already defined to avoid conflicts in tests
if [[ -z "${RED:-}" ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly PURPLE='\033[0;35m'
    readonly CYAN='\033[0;36m'
    readonly GRAY='\033[0;90m'
    readonly BOLD='\033[1m'
    readonly NC='\033[0m' # No Color
fi

# Configuration
PC_DIR="${PC_DIR:-${HOME}/.project-contexts}"
STASH_DIR="${STASH_DIR:-${PC_DIR}/.stash}"
BACKUP_DIR="${BACKUP_DIR:-${PC_DIR}/.backups}"
HISTORY_FILE="${HISTORY_FILE:-${PC_DIR}/.history}"
ACTIVE_LINK="${ACTIVE_LINK:-${PC_DIR}/.active}"
MAX_BACKUPS="${MAX_BACKUPS:-10}"
MAX_HISTORY="${MAX_HISTORY:-1000}"

# Error handling
error() {
    echo -e "${RED}Error: $*${NC}" >&2
}

warn() {
    echo -e "${YELLOW}Warning: $*${NC}" >&2
}

info() {
    echo -e "${BLUE}$*${NC}"
}

success() {
    echo -e "${GREEN}$*${NC}"
}

debug() {
    [[ "${DEBUG:-0}" == "1" ]] && echo -e "${GRAY}DEBUG: $*${NC}" >&2 || true
}

# Cleanup on exit
cleanup() {
    local exit_code=$?
    debug "Cleaning up (exit code: $exit_code)"
    # Add cleanup tasks here if needed
    return $exit_code
}

# Set up error handling
setup_error_handling() {
    trap cleanup EXIT
    trap 'error "Script interrupted"; exit 130' INT TERM
}

# Ensure directory exists with proper permissions
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        debug "Creating directory: $dir"
        mkdir -p "$dir" || {
            error "Failed to create directory: $dir"
            return 1
        }
    fi
}

# Get timestamp in consistent format
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Get date in consistent format
get_date() {
    date '+%Y-%m-%d'
}

# Validate context name
validate_context_name() {
    local name="$1"
    
    # Check if empty
    if [[ -z "$name" ]]; then
        error "Context name cannot be empty"
        return 1
    fi
    
    # Check for invalid characters
    if [[ ! "$name" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
        error "Context name can only contain letters, numbers, dots, hyphens, and underscores"
        return 1
    fi
    
    # Check for reserved names
    case "$name" in
        .|..|.active|.stash|.backups|.history|.todos.db)
            error "Reserved name: $name"
            return 1
            ;;
    esac
    
    return 0
}

# Get current context from symlink
get_current_context() {
    if [[ -L "$ACTIVE_LINK" ]]; then
        basename "$(readlink "$ACTIVE_LINK")"
    else
        echo ""
    fi
}

# Set current context
set_current_context() {
    local context="$1"
    local context_dir="${PC_DIR}/${context}"
    
    validate_context_name "$context" || return 1
    ensure_dir "$context_dir" || return 1
    
    # Remove old symlink if exists
    [[ -L "$ACTIVE_LINK" ]] && rm -f "$ACTIVE_LINK"
    
    # Create new symlink
    ln -sf "$context_dir" "$ACTIVE_LINK" || {
        error "Failed to set active context"
        return 1
    }
    
    debug "Set active context to: $context"
}

# Get context directory
get_context_dir() {
    local context="${1:-$(get_current_context)}"
    
    if [[ -z "$context" ]]; then
        error "No context specified and no active context"
        return 1
    fi
    
    echo "${PC_DIR}/${context}"
}

# Check if file exists and is readable
check_file() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    if [[ ! -r "$file" ]]; then
        error "Cannot read file: $file"
        return 1
    fi
    
    return 0
}

# Safe copy with backup
safe_copy() {
    local src="$1"
    local dst="$2"
    local backup="${3:-true}"
    
    if [[ ! -f "$src" ]]; then
        error "Source file does not exist: $src"
        return 1
    fi
    
    # Create backup if destination exists
    if [[ "$backup" == "true" && -f "$dst" ]]; then
        local backup_name="${dst}.backup.$(date +%Y%m%d_%H%M%S)"
        debug "Creating backup: $backup_name"
        cp "$dst" "$backup_name" || {
            error "Failed to create backup"
            return 1
        }
    fi
    
    # Copy file
    cp "$src" "$dst" || {
        error "Failed to copy $src to $dst"
        return 1
    }
    
    debug "Copied $src to $dst"
}

# Check git status
check_git_status() {
    local allow_dirty="${1:-false}"
    
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        debug "Not in a git repository"
        return 0
    fi
    
    if [[ "$allow_dirty" == "false" ]] && ! git diff-index --quiet HEAD -- 2>/dev/null; then
        warn "You have uncommitted changes in your git repository"
        echo -n "Continue anyway? [y/N] "
        read -r response
        [[ "$response" =~ ^[Yy]$ ]] || return 1
    fi
    
    return 0
}

# Get git branch name
get_git_branch() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git branch --show-current 2>/dev/null || echo "detached"
    else
        echo ""
    fi
}

# Get git root directory
get_git_root() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git rev-parse --show-toplevel 2>/dev/null
    else
        echo ""
    fi
}

# Add entry to history
add_to_history() {
    local action="$1"
    local details="${2:-}"
    local timestamp=$(get_timestamp)
    
    ensure_dir "$PC_DIR" || return 1
    
    echo "[$timestamp] $action $details" >> "$HISTORY_FILE"
    
    # Trim history if too large
    if [[ -f "$HISTORY_FILE" ]] && [[ $(wc -l < "$HISTORY_FILE") -gt $MAX_HISTORY ]]; then
        debug "Trimming history file"
        tail -n $MAX_HISTORY "$HISTORY_FILE" > "${HISTORY_FILE}.tmp"
        mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
    fi
}

# Create backup of context
create_backup() {
    local context="${1:-$(get_current_context)}"
    local context_dir
    
    context_dir=$(get_context_dir "$context") || return 1
    
    if [[ ! -d "$context_dir" ]]; then
        debug "No context directory to backup"
        return 0
    fi
    
    ensure_dir "$BACKUP_DIR" || return 1
    
    local backup_name="${context}_$(date +%Y%m%d_%H%M%S).tar.gz"
    local backup_path="${BACKUP_DIR}/${backup_name}"
    
    debug "Creating backup: $backup_path"
    tar -czf "$backup_path" -C "$PC_DIR" "$context" 2>/dev/null || {
        error "Failed to create backup"
        return 1
    }
    
    # Clean old backups
    local backup_count=$(find "$BACKUP_DIR" -name "${context}_*.tar.gz" -type f | wc -l)
    if [[ $backup_count -gt $MAX_BACKUPS ]]; then
        debug "Cleaning old backups"
        find "$BACKUP_DIR" -name "${context}_*.tar.gz" -type f -print0 | \
            sort -z | head -z -n -$MAX_BACKUPS | xargs -0 rm -f
    fi
    
    debug "Backup created: $backup_name"
}

# Display file content with line numbers and color
display_file() {
    local file="$1"
    local title="${2:-}"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    if [[ -n "$title" ]]; then
        echo -e "${BOLD}${BLUE}=== $title ===${NC}"
    fi
    
    # Use cat -n for line numbers if available, otherwise nl
    if command -v cat >/dev/null 2>&1; then
        cat -n "$file" | while IFS= read -r line; do
            echo -e "${GRAY}${line}${NC}"
        done
    else
        nl -ba "$file" | while IFS= read -r line; do
            echo -e "${GRAY}${line}${NC}"
        done
    fi
    
    echo
}

# Escape string for use in regex
escape_regex() {
    local string="$1"
    printf '%s\n' "$string" | sed 's/[[\.*^$()+?{|]/\\&/g'
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get file size in human readable format
get_file_size() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        echo "0"
        return
    fi
    
    if command_exists stat; then
        # Try GNU stat first, then BSD stat
        stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "0"
    else
        wc -c < "$file" | tr -d ' '
    fi
}

# Format file size for display
format_size() {
    local size="$1"
    local units=("B" "KB" "MB" "GB")
    local unit=0
    
    while (( size > 1024 && unit < ${#units[@]} - 1 )); do
        size=$((size / 1024))
        ((unit++))
    done
    
    echo "${size}${units[$unit]}"
}

# Export functions and variables for use in scripts
export -f error warn info success debug
export -f ensure_dir get_timestamp get_date
export -f validate_context_name get_current_context set_current_context
export -f get_context_dir check_file safe_copy
export -f check_git_status get_git_branch get_git_root
export -f add_to_history create_backup display_file
export -f escape_regex command_exists get_file_size format_size

# Initialize PC directory structure if needed
init_pc_structure() {
    ensure_dir "$PC_DIR"
    ensure_dir "$STASH_DIR"
    ensure_dir "$BACKUP_DIR"
    
    # Create history file if doesn't exist
    [[ -f "$HISTORY_FILE" ]] || touch "$HISTORY_FILE"
}