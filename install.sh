#!/bin/bash
# Installation script for Project Context Manager

set -euo pipefail

echo "Project Context Manager Installation"
echo "===================================="
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
echo "Installing pc to $INSTALL_PATH"

# Create directory if needed
mkdir -p "$(dirname "$INSTALL_PATH")"

# Copy new version
cp pc.sh "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

echo ""
echo "Installation complete!"

# Install shell completions
echo ""
echo "Installing shell completions..."

# Bash completion
if [[ -d "$HOME/.bash_completion.d" ]] || [[ -f "$HOME/.bashrc" ]]; then
    mkdir -p "$HOME/.bash_completion.d"
    cp completions/pc.bash "$HOME/.bash_completion.d/pc" 2>/dev/null || true
    echo "Bash completion installed to ~/.bash_completion.d/pc"
    echo "Add to ~/.bashrc: source ~/.bash_completion.d/pc"
fi

# Zsh completion  
if [[ -d "$HOME/.oh-my-zsh" ]] || [[ -f "$HOME/.zshrc" ]]; then
    mkdir -p "$HOME/.zsh/completions"
    cp completions/_pc "$HOME/.zsh/completions/_pc" 2>/dev/null || true
    echo "Zsh completion installed to ~/.zsh/completions/_pc"
    echo "Add to ~/.zshrc: fpath=(~/.zsh/completions \$fpath)"
fi

echo ""
# Show version info if available
if [[ -f "CHANGELOG.md" ]]; then
    echo "Latest changes:"
    # Extract the most recent version section
    awk '/^## \[/ {if (NR>1) exit} /^##/ {p=1} p' CHANGELOG.md | head -20
fi
echo ""
echo "Run 'pc help' to see all available commands"