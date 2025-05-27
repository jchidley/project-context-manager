# project-context-manager

Development tasks for the project-context-manager.

## test
> Run all tests using BATS (Bash Automated Testing System)

~~~bash
set -e

# Check if bats is installed
if ! command -v bats &> /dev/null; then
    echo "BATS is not installed. Installing via git..."
    
    # Clone bats-core if not exists
    if [[ ! -d "tests/bats" ]]; then
        git clone https://github.com/bats-core/bats-core.git tests/bats
    fi
    
    # Use local bats
    BATS_BIN="tests/bats/bin/bats"
else
    BATS_BIN="bats"
fi

# Run tests
echo "Running tests..."
$BATS_BIN tests/*.bats
~~~

## test-watch
> Run tests in watch mode (requires entr)

~~~bash
if ! command -v entr &> /dev/null; then
    echo "entr is not installed. Install with: apt-get install entr"
    exit 1
fi

echo "Watching for changes..."
find . -name "*.sh" -o -name "*.bats" -o -name "*.bash" | entr -c mask test
~~~

## lint
> Run shellcheck on all shell scripts

~~~bash
set -e

# Check if shellcheck is installed
if ! command -v shellcheck &> /dev/null; then
    echo "shellcheck is not installed."
    echo "Install with: apt-get install shellcheck"
    exit 1
fi

# Find all shell scripts
echo "Running shellcheck..."
find . -name "*.sh" -o -name "*.bash" | grep -v tests/bats | while read -r file; do
    echo "Checking: $file"
    shellcheck -x "$file"
done

# Check main pc script without extension
if [[ -f "pc" ]]; then
    echo "Checking: pc"
    shellcheck -x pc
fi

echo "✓ All files passed shellcheck"
~~~

## lint-fix
> Run shellcheck with fixing suggestions

~~~bash
set -e

if ! command -v shellcheck &> /dev/null; then
    echo "shellcheck is not installed."
    exit 1
fi

echo "Running shellcheck with fix suggestions..."
find . -name "*.sh" -o -name "*.bash" | grep -v tests/bats | while read -r file; do
    echo "=== $file ==="
    shellcheck -x -f diff "$file" || true
    echo
done
~~~

## install
> Install pc to ~/.local/bin

~~~bash
set -e

# Default to main pc.sh script
SCRIPT="${1:-pc.sh}"

if [[ ! -f "$SCRIPT" ]]; then
    echo "Error: $SCRIPT not found"
    exit 1
fi

# Create ~/.local/bin if it doesn't exist
mkdir -p ~/.local/bin

# Copy script
echo "Installing $SCRIPT to ~/.local/bin/pc"
cp "$SCRIPT" ~/.local/bin/pc
chmod +x ~/.local/bin/pc

# Install shell completions if they exist
if [[ -f "completions/pc.bash" ]]; then
    echo "Installing bash completions..."
    mkdir -p ~/.local/share/bash-completion/completions
    cp completions/pc.bash ~/.local/share/bash-completion/completions/pc
fi

if [[ -f "completions/pc.zsh" ]]; then
    echo "Installing zsh completions..."
    mkdir -p ~/.local/share/zsh/site-functions
    cp completions/pc.zsh ~/.local/share/zsh/site-functions/_pc
fi

echo "✓ Installation complete"
echo ""
echo "Make sure ~/.local/bin is in your PATH:"
echo '  export PATH="$HOME/.local/bin:$PATH"'
~~~

## uninstall
> Remove pc from ~/.local/bin

~~~bash
echo "Removing pc..."
rm -f ~/.local/bin/pc
rm -f ~/.local/share/bash-completion/completions/pc
rm -f ~/.local/share/zsh/site-functions/_pc

echo "✓ Uninstall complete"
~~~

## coverage
> Generate test coverage report

~~~bash
set -e

# This is a simple coverage check - counts tested vs total functions
echo "Analyzing test coverage..."

# Count functions in lib/common.sh
total_functions=$(grep -c "^[[:space:]]*[[:alnum:]_]*()[[:space:]]*{" lib/common.sh || echo 0)

# Count function calls in tests
tested_functions=$(grep -h "run [[:alnum:]_]*" tests/*.bats | \
    sed 's/.*run \([[:alnum:]_]*\).*/\1/' | \
    sort -u | wc -l)

echo "Total functions: $total_functions"
echo "Tested functions: $tested_functions"

if [[ $total_functions -gt 0 ]]; then
    coverage=$((tested_functions * 100 / total_functions))
    echo "Coverage: ${coverage}%"
fi
~~~

## clean
> Clean test artifacts and temporary files

~~~bash
echo "Cleaning test artifacts..."
rm -rf tests/bats
rm -rf tests/test-tmp
rm -f ./*.backup.*
find . -name "*.tmp" -delete

echo "✓ Clean complete"
~~~

## check
> Run all checks (lint + test)

~~~bash
set -e
mask lint
echo ""
mask test
~~~

## docs
> Generate documentation from code

~~~bash
echo "Generating documentation..."

# Extract function documentation from lib/common.sh
echo "# API Reference" > docs/API.md
echo "" >> docs/API.md
echo "## Common Library Functions" >> docs/API.md
echo "" >> docs/API.md

grep -B1 "^[[:alnum:]_]*()[[:space:]]*{" lib/common.sh | \
    grep -E "^#|^[[:alnum:]_]*\(\)" | \
    sed 's/^# //' | \
    sed 's/().*{/()/' | \
    awk 'BEGIN{print "| Function | Description |"; print "|----------|-------------|"} 
         /^[^#]/ {if (desc) print "| " $0 " | " desc " |"; desc=""} 
         /^[^(]/ {desc=$0}' >> docs/API.md

echo "✓ Documentation generated in docs/API.md"
~~~

## release (version)
> Create a new release

> **POSITIONAL ARGUMENTS**
> * version - Version number (e.g., 0.3.0)

~~~bash
set -e

VERSION="$1"

if [[ -z "$VERSION" ]]; then
    echo "Error: Version number required"
    echo "Usage: mask release VERSION"
    exit 1
fi

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in format X.Y.Z"
    exit 1
fi

echo "Preparing release v${VERSION}..."

# Run checks
mask check

# Update version in files
echo "Updating version numbers..."
sed -i "s/Version: .*/Version: ${VERSION}/" README.md || true
sed -i "s/PROJECT_CONTEXT_VERSION=.*/PROJECT_CONTEXT_VERSION=\"${VERSION}\"/" pc.sh || true

# Update changelog
echo "## v${VERSION} - $(date +%Y-%m-%d)" >> CHANGELOG.md.new
echo "" >> CHANGELOG.md.new
echo "### Added" >> CHANGELOG.md.new
echo "- " >> CHANGELOG.md.new
echo "" >> CHANGELOG.md.new
cat CHANGELOG.md >> CHANGELOG.md.new
mv CHANGELOG.md.new CHANGELOG.md

echo "✓ Release preparation complete"
echo ""
echo "Next steps:"
echo "1. Update CHANGELOG.md with release notes"
echo "2. Commit changes: git commit -am 'Release v${VERSION}'"
echo "3. Tag release: git tag -a v${VERSION} -m 'Release v${VERSION}'"
echo "4. Push: git push && git push --tags"
~~~