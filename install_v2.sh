#!/bin/bash
# Installation script for pc v2 with plain text storage

set -euo pipefail

echo "PC v2 Installation Script"
echo "========================"
echo ""

# Check if old version exists
if command -v pc &> /dev/null; then
    OLD_PC=$(which pc)
    echo "Found existing pc at: $OLD_PC"
    echo ""
    
    # Check if database exists
    if [[ -f "$HOME/.project-contexts/todos.db" ]]; then
        echo "SQLite database found. Running migration..."
        ./migrate_todos_to_plain_text.sh
        echo ""
    fi
    
    # Backup old version
    if [[ -f "$OLD_PC" ]]; then
        echo "Backing up old version to ${OLD_PC}.v1"
        sudo cp "$OLD_PC" "${OLD_PC}.v1"
    fi
fi

# Install new version
INSTALL_PATH="${HOME}/.local/bin/pc"
echo "Installing pc v2 to $INSTALL_PATH"

# Create directory if needed
mkdir -p "$(dirname "$INSTALL_PATH")"

# Copy new version
cp pc_v2.sh "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

echo ""
echo "Installation complete!"
echo ""
echo "What's new in v2:"
echo "- Plain text TODO.md files (no more SQLite)"
echo "- Full integration with Claude Code slash commands"
echo "- Git-style stash and diff commands"
echo "- Improved context switching"
echo ""
echo "Run 'pc help' to see all available commands"