#!/bin/bash
# Enhanced init command for Claude-ready projects

# Enhanced init command that creates full project structure
cmd_init_enhanced() {
    local context="${1:-}"
    local project_dir="${2:-}"
    
    
    if [[ -z "$context" ]]; then
        error "Context name required"
        echo "Usage: pc init <name> [project_directory]"
        echo "       pc init <name> .  (to use current directory)"
        return 1
    fi
    
    validate_context_name "$context" || return 1
    
    local context_dir="${PC_DIR}/${context}"
    
    if [[ -d "$context_dir" ]]; then
        error "Context already exists: $context"
        return 1
    fi
    
    # If no directory specified, create a subdirectory with the context name
    if [[ -z "$project_dir" ]]; then
        project_dir="./${context}"
        info "No directory specified, will create: $project_dir"
    fi
    
    # If project_dir is "." (current directory), check if it's safe
    if [[ "$project_dir" == "." ]]; then
        project_dir="$(pwd)"
        # Check if current directory has existing files
        local file_count=$(find . -maxdepth 1 -type f | wc -l)
        if [[ $file_count -gt 0 ]]; then
            echo "Warning: Current directory contains $file_count file(s)"
            echo -n "Initialize project in current directory? (y/N): "
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                info "Initialization cancelled"
                return 1
            fi
        fi
    fi
    
    info "Initializing Claude-ready project: $context"
    
    # Create context directory
    ensure_dir "$context_dir" || return 1
    set_current_context "$context" || return 1
    
    # Create project directory if it doesn't exist
    if [[ ! -d "$project_dir" ]]; then
        info "Creating project directory: $project_dir"
        mkdir -p "$project_dir"
    fi
    
    # Initialize git if not already a repo
    if [[ ! -d "$project_dir/.git" ]]; then
        info "Initializing git repository"
        (cd "$project_dir" && git init)
    fi
    
    # Create CLAUDE.md
    if [[ ! -f "$project_dir/CLAUDE.md" ]]; then
        cat > "$project_dir/CLAUDE.md" << 'EOF'
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

[One paragraph describing what this project does and why it exists]

## Technical Stack

- Language: [e.g., Bash, Rust, Python with uv, TypeScript with Bun]
- Database: [e.g., SQLite at ~/.local/share/projectname/]
- Testing: [e.g., Bats, pytest, Jest]
- Task Runner: mask (maskfile.md)
- CI/CD: [e.g., GitHub Actions]

## Architecture Overview

### Core Design Pattern
[Describe the main architectural approach]

### Key Components
- Component 1: [Purpose and location]
- Component 2: [Purpose and location]

### Data Flow
[How data moves through the system]

## Essential Commands

```bash
# Development
mask dev        # Start development environment
mask test       # Run all tests
mask lint       # Run linting checks
mask build      # Build for production

# Installation
mask install    # Install to ~/.local/bin/
```

## Project Structure

```
.
├── src/            # Source code
├── tests/          # Test files
├── docs/           # Documentation
├── maskfile.md     # Task automation
├── CLAUDE.md       # This file
├── REQUIREMENTS.md # Project requirements
├── TODO.md         # Task tracking
└── HANDOFF.md      # Work state
```

## Key Implementation Details

### Critical Functions
- `main()` - Entry point, handles...
- `process_data()` - Core logic for...

### Design Decisions
- Choice 1: Chose X over Y because...
- Choice 2: Implemented Z pattern for...

### Common Pitfalls
- Don't forget to...
- Always check...

## Constraints & Requirements

### Must Support
- Feature 1: [Description]
- Feature 2: [Description]
- Platform: [Linux, macOS, Windows]

### Performance Targets
- Response time: < Xms
- Memory usage: < XMB
- Concurrent operations: X

### Security Considerations
- Input validation: [approach]
- Secret management: [approach]
- Data protection: [approach]

## Development Workflow

### Starting Work
1. `pc switch $context` - Load project context
2. Check HANDOFF.md for current state
3. Review TODO.md for tasks
4. Run `mask dev` to start

### During Development
- Use `mask test` frequently
- Run `mask lint` before commits
- Update TODO.md as you work
- Keep HANDOFF.md current

### Ending Work
1. Update HANDOFF.md with current state
2. Run `mask test` to ensure stability
3. Commit changes
4. `pc stash` or `pc log` to save context

## Testing Standards

- Write tests first (TDD)
- Test coverage target: X%
- Integration tests required for: [list]
- Performance tests required for: [list]

## External Dependencies

### Services
- Service A: [Purpose, API endpoint, auth method]
- Service B: [Purpose, configuration location]

### Libraries
- Library X: [Purpose, version constraints]
- Library Y: [Purpose, special configuration]

## Deployment

### Local Installation
```bash
mask install
```

### Production Deployment
[Deployment process and requirements]

## Related Documentation

- REQUIREMENTS.md - Full feature requirements
- PROJECT_WISDOM.md - Accumulated technical insights
- TODO.md - Current task list
- HANDOFF.md - Active work state
EOF
        success "Created CLAUDE.md"
    fi
    
    # Create REQUIREMENTS.md
    if [[ ! -f "$project_dir/REQUIREMENTS.md" ]]; then
        cat > "$project_dir/REQUIREMENTS.md" << 'EOF'
# Requirements

## Overview

[Brief description of what this project aims to achieve]

## User Stories

### As a [user type]
- I want to [action]
- So that [benefit]

## Functional Requirements

### Core Features (MVP)
- [ ] Feature 1: [Description]
  - Acceptance criteria: [How we know it's done]
  - Technical notes: [Implementation hints]

- [ ] Feature 2: [Description]
  - Acceptance criteria: [How we know it's done]
  - Technical notes: [Implementation hints]

### Future Features
- [ ] Feature 3: [Description]
- [ ] Feature 4: [Description]

## Technical Requirements

### Performance
- Response time: < Xms for [operation]
- Throughput: X operations/second
- Resource usage: < X MB memory

### Compatibility
- Operating Systems: Linux, macOS, Windows (WSL)
- Shell: Bash 4.0+
- Dependencies: [List any required tools]

### Data Requirements
- Storage location: ~/.local/share/projectname/
- Data format: [JSON, YAML, SQLite, etc.]
- Backup strategy: [Approach]

## User Interface

### Command-Line Interface
```bash
# Basic usage
command [options] <arguments>

# Examples
command init        # Initialize
command process     # Process data
command --help      # Show help
```

### Configuration
- Config location: ~/.config/projectname/
- Environment variables: PROJECT_*
- Command-line flags override config

## Security Requirements

- [ ] Input validation for all user inputs
- [ ] No hardcoded secrets or credentials
- [ ] Secure storage of sensitive data
- [ ] Audit logging for important operations

## Quality Requirements

### Testing
- Unit test coverage: > 80%
- Integration tests for all workflows
- Performance benchmarks
- Security scanning

### Documentation
- README.md with quick start
- CLAUDE.md for development
- Man page or --help for users
- Inline code comments

## Constraints

### Technical Constraints
- Must work offline
- Single binary/script distribution preferred
- No external service dependencies for core features

### Business Constraints
- Open source license (MIT/Apache)
- Must be maintainable by small team
- Follow existing project patterns

## Success Criteria

### Launch Criteria
- [ ] All MVP features implemented
- [ ] Tests passing with > 80% coverage
- [ ] Documentation complete
- [ ] Performance targets met
- [ ] Security review passed

### Post-Launch Metrics
- User adoption: X users in Y days
- Performance: X operations/second sustained
- Reliability: X% uptime
- User satisfaction: X/5 rating

## Appendix

### Glossary
- Term 1: Definition
- Term 2: Definition

### References
- [Relevant documentation or standards]
- [Similar projects or inspiration]
EOF
        success "Created REQUIREMENTS.md"
    fi
    
    # Create maskfile.md
    if [[ ! -f "$project_dir/maskfile.md" ]]; then
        cat > "$project_dir/maskfile.md" << 'EOF'
# Taskfile for project automation
# https://github.com/jacobdeichert/mask

## init
> Initialize project environment

~~~bash
set -euo pipefail
echo "Initializing project..."

# Create necessary directories
mkdir -p ~/.local/share/projectname
mkdir -p ~/.config/projectname

# Install dependencies if needed
# uv sync  # For Python projects
# cargo build  # For Rust projects
# npm install  # For Node projects

echo "Project initialized successfully!"
~~~

## dev
> Start development environment

~~~bash
set -euo pipefail
echo "Starting development environment..."

# Add your development server or watch commands
# Examples:
# cargo watch -x 'run -- --dev'
# uv run python -m projectname --dev
# npm run dev
~~~

## test
> Run all tests

~~~bash
set -euo pipefail
echo "Running tests..."

# Add your test commands
# bats tests/         # For bash projects
# cargo test          # For Rust projects  
# uv run pytest       # For Python projects
# npm test            # For Node projects

echo "Tests completed!"
~~~

## lint
> Run linting and formatting checks

~~~bash
set -euo pipefail
echo "Running linters..."

# Add your lint commands
# shellcheck *.sh     # For bash
# cargo clippy        # For Rust
# ruff check .        # For Python
# eslint .            # For JavaScript

echo "Linting completed!"
~~~

## build
> Build project for release

~~~bash
set -euo pipefail
echo "Building project..."

# Add your build commands
# cargo build --release
# uv build
# npm run build

echo "Build completed!"
~~~

## install
> Install project locally

~~~bash
set -euo pipefail
echo "Installing to ~/.local/bin/..."

# Add your install commands
# cp target/release/binary ~/.local/bin/
# uv pip install -e .
# npm link

echo "Installation completed!"
~~~

## clean
> Clean build artifacts

~~~bash
set -euo pipefail
echo "Cleaning build artifacts..."

# Add your clean commands
# rm -rf target/      # Rust
# rm -rf dist/        # Python
# rm -rf node_modules/ # Node

echo "Clean completed!"
~~~

## release (version)
> Create a new release

**OPTIONS**
* version: Version number (e.g., 0.1.0)

~~~bash
set -euo pipefail

if [[ -z "$version" ]]; then
    echo "Error: Version required"
    echo "Usage: mask release 0.1.0"
    exit 1
fi

echo "Creating release v$version..."

# Update version in relevant files
# sed -i "s/version = .*/version = \"$version\"/" Cargo.toml
# sed -i "s/version = .*/version = \"$version\"/" pyproject.toml
# npm version $version

# Create git tag
git add -A
git commit -m "chore: release v$version"
git tag -a "v$version" -m "Release v$version"

echo "Release v$version created!"
echo "Don't forget to: git push origin main --tags"
~~~
EOF
        success "Created maskfile.md"
    fi
    
    # Create enhanced HANDOFF.md in context directory
    cat > "${context_dir}/HANDOFF.md" << EOF
# Project: $context
Updated: $(get_timestamp)

## Current State
Status: New Claude-ready project initialized
Latest: Created project structure with CLAUDE.md, REQUIREMENTS.md, maskfile.md

## Essential Context
- Project initialized with full Claude-ready structure
- Review REQUIREMENTS.md to define project goals
- Update CLAUDE.md with specific technical decisions
- Use maskfile.md for all task automation

## Next Step
1. Define project purpose in CLAUDE.md
2. Fill out requirements in REQUIREMENTS.md
3. Set up development environment with \`mask init\`

## If Blocked
- Check CLAUDE_PROJECT_SETUP_GUIDE.md for detailed guidance
- Ensure all dependencies are installed
- Review similar projects for patterns

## Related Documents
- CLAUDE.md - Project-specific AI instructions (in project root)
- REQUIREMENTS.md - Feature requirements (in project root)
- maskfile.md - Task automation (in project root)
- TODO.md - Task tracking (managed by pc)
- PROJECT_WISDOM.md - Technical insights (managed by pc)
EOF

    # Create enhanced TODO.md in context directory
    cat > "${context_dir}/TODO.md" << EOF
# TODO - $context

Last updated: $(get_timestamp)

## To Do - Project Setup

- [ ] Update CLAUDE.md with specific project purpose <!-- created:$(get_date) -->
- [ ] Define MVP requirements in REQUIREMENTS.md <!-- created:$(get_date) -->
- [ ] Configure maskfile.md for project-specific tasks <!-- created:$(get_date) -->
- [ ] Set up development environment with mask init <!-- created:$(get_date) -->
- [ ] Create initial project structure (src/, tests/, docs/) <!-- created:$(get_date) -->
- [ ] Initialize testing framework <!-- created:$(get_date) -->
- [ ] Set up CI/CD pipeline <!-- created:$(get_date) -->

## To Do - Development

- [ ] Implement core functionality <!-- created:$(get_date) -->
- [ ] Write unit tests <!-- created:$(get_date) -->
- [ ] Add integration tests <!-- created:$(get_date) -->
- [ ] Create user documentation <!-- created:$(get_date) -->

## In Progress

## Done
EOF

    # Create PROJECT_WISDOM.md
    cat > "${context_dir}/PROJECT_WISDOM.md" << EOF
# Project Wisdom - $context

Technical insights and learnings accumulated during development.

## Architecture Decisions

### Decision: [Title]
**Date**: $(get_date)
**Context**: What situation led to this decision
**Decision**: What was decided
**Consequences**: What are the implications

## Technical Insights

### Insight: [Title]
**Date**: $(get_date)
**Problem**: What issue was encountered
**Solution**: How it was resolved
**Learning**: Key takeaway for future

## Performance Optimizations

### Optimization: [Title]
**Date**: $(get_date)
**Bottleneck**: What was slow
**Solution**: How it was improved
**Result**: Performance improvement achieved

## Gotchas & Pitfalls

### Gotcha: [Title]
**Date**: $(get_date)
**Issue**: What went wrong
**Cause**: Why it happened
**Prevention**: How to avoid it

## Best Practices

### Practice: [Title]
**Date**: $(get_date)
**Pattern**: Recommended approach
**Rationale**: Why it works well
**Example**: Code snippet or usage

## External Resources

- [Resource 1]: URL or reference
- [Resource 2]: URL or reference
EOF

    # Create .gitignore if it doesn't exist
    if [[ ! -f "$project_dir/.gitignore" ]]; then
        cat > "$project_dir/.gitignore" << 'EOF'
# Build artifacts
target/
dist/
build/
*.egg-info/
__pycache__/
*.pyc
node_modules/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Environment
.env
.env.local
.venv/
venv/

# Logs
*.log
logs/

# Test coverage
coverage/
.coverage
htmlcov/
*.cover

# Temporary files
tmp/
temp/
.cache/
EOF
        success "Created .gitignore"
    fi
    
    add_to_history "init" "$context (enhanced)"
    
    # Get absolute path for display
    local abs_project_dir=$(cd "$project_dir" && pwd)
    
    echo ""
    success "Initialized Claude-ready project: $context"
    echo ""
    info "Created in $abs_project_dir:"
    echo "  - CLAUDE.md       : AI development instructions"
    echo "  - REQUIREMENTS.md : Project requirements"  
    echo "  - maskfile.md     : Task automation"
    echo "  - .gitignore      : Git ignore patterns"
    echo ""
    info "Context files in ~/.project-contexts/$context/:"
    echo "  - HANDOFF.md      : Current work state"
    echo "  - TODO.md         : Task tracking"
    echo "  - PROJECT_WISDOM.md : Technical insights"
    echo ""
    info "Next steps:"
    echo "  1. cd $abs_project_dir"
    echo "  2. Review and update CLAUDE.md and REQUIREMENTS.md"
    echo "  3. Run 'mask init' to set up development environment"
    echo "  4. Start development with 'pc switch $context'"
}