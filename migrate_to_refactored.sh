#!/bin/bash
# migrate_to_refactored.sh - Replace old pc with refactored version

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}=== Project Context Manager Migration ===${NC}"
echo "This will replace the old SQLite-based pc with the refactored plain-text version."
echo

# Check if pc is installed
if [[ ! -f "$HOME/.local/bin/pc" ]]; then
    echo -e "${RED}Error: pc is not installed at ~/.local/bin/pc${NC}"
    exit 1
fi

# Check if refactored version exists
if [[ ! -f "pc_refactored.sh" ]]; then
    echo -e "${RED}Error: pc_refactored.sh not found in current directory${NC}"
    exit 1
fi

# Backup old version
echo -e "${YELLOW}Backing up old pc...${NC}"
cp "$HOME/.local/bin/pc" "$HOME/.local/bin/pc.old-sqlite"
echo -e "${GREEN}✓ Backed up to ~/.local/bin/pc.old-sqlite${NC}"

# Install refactored version
echo -e "${YELLOW}Installing refactored version...${NC}"
cp pc_refactored.sh "$HOME/.local/bin/pc"
chmod +x "$HOME/.local/bin/pc"
echo -e "${GREEN}✓ Installed new version${NC}"

# Copy library files
echo -e "${YELLOW}Installing library files...${NC}"
mkdir -p "$HOME/.local/share/pc/lib"
cp lib/*.sh "$HOME/.local/share/pc/lib/"
echo -e "${GREEN}✓ Installed library files${NC}"

echo
echo -e "${GREEN}Migration complete!${NC}"
echo
echo "The new version uses plain-text TODO.md files instead of SQLite."
echo "Your existing TODO.md files in each context directory will be used."
echo
echo "If you need to revert: cp ~/.local/bin/pc.old-sqlite ~/.local/bin/pc"