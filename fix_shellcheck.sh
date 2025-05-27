#!/usr/bin/env bash
# Script to fix common shellcheck warnings

set -euo pipefail

# Fix SC2155: Declare and assign separately to avoid masking return values
# This pattern: local var=$(command)
# Should be: local var; var=$(command)

fix_sc2155() {
    local file="$1"
    echo "Fixing SC2155 in $file..."
    
    # Create a temporary file
    local temp_file="${file}.tmp"
    
    # Process the file line by line
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*local[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)=\$\((.*)\)[[:space:]]*$ ]]; then
            local var_name="${BASH_REMATCH[1]}"
            local command="${BASH_REMATCH[2]}"
            # Split declaration and assignment
            echo "    local ${var_name}"
            echo "    ${var_name}=\$(${command})"
        else
            echo "$line"
        fi
    done < "$file" > "$temp_file"
    
    # Replace original file
    mv "$temp_file" "$file"
}

# Fix SC2119: Use function "$@" if function's $1 should mean script's $1
fix_sc2119() {
    local file="$1"
    echo "Fixing SC2119 in $file..."
    
    # For check_git_status, it has a default parameter
    sed -i 's/check_git_status || return 1/check_git_status false || return 1/g' "$file"
}

# Main
echo "Fixing shellcheck warnings..."

# Fix main script
fix_sc2155 "pc_refactored.sh"
fix_sc2119 "pc_refactored.sh"

# Fix library files
for lib_file in lib/*.sh; do
    if [[ -f "$lib_file" ]]; then
        fix_sc2155 "$lib_file"
    fi
done

# Fix test files
sed -i 's/local backup_files=\$(ls/local backup_files\n    backup_files=\$(find . -name/g' tests/common.bats

echo "Done! Run shellcheck again to verify fixes."