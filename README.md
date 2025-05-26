# Project Context Manager (pc)

A developer tool for managing context across multiple concurrent projects. Never lose your mental state when switching between projects again.

## The Problem

When working on multiple projects simultaneously, developers face context loss:
- Where was I in this project?
- What was I trying to solve?
- What decisions did I make and why?
- What tasks are still pending?

Traditional tools (git, task managers, notes) solve pieces but not the whole problem.

## The Solution

Project Context Manager (`pc`) provides a git-like interface for managing project-specific state:

```bash
# Switch to a project context
pc switch my-project

# Save current work state
pc checkpoint "Implemented user auth, testing next"

# See what you were doing
pc status

# Manage todos with SQLite persistence
pc todo add "Write tests for auth module"
pc todo list

# Stash context temporarily
pc stash
pc stash pop

# View context history
pc log
```

## Key Features

- **Zero Dependencies**: Pure bash implementation, works everywhere
- **Git-Aware**: Respects version control, warns on uncommitted changes
- **Persistent Todos**: SQLite-backed task tracking survives context switches
- **GitHub Integration**: Optional two-way sync with GitHub issues
- **Non-Destructive**: Automatic backups before operations
- **Human-Readable**: All state stored in markdown files

## Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/project-context-manager.git
cd project-context-manager

# Install the unified version (recommended)
cp pc_unified_prototype.sh ~/.local/bin/pc
chmod +x ~/.local/bin/pc

# Or try the simpler versions
cp pc_prototype.sh ~/.local/bin/pc-basic      # Basic functionality
cp pc_enhanced.sh ~/.local/bin/pc-enhanced    # Git-like features
```

## Quick Start

```bash
# Initialize context for current project
pc init

# Start working
pc checkpoint "Starting new feature"

# Add todos
pc todo add "Implement user authentication"
pc todo add "Write unit tests"

# Switch to another project
cd ~/another-project
pc switch another-project

# Come back later
pc switch my-project
pc status  # See where you left off
```

## How It Works

Project contexts are stored in `~/.project-contexts/` with this structure:

```
~/.project-contexts/
├── .active -> current_project (symlink)
├── .todos.db (SQLite database)
├── project-name/
│   ├── HANDOFF.md (current state)
│   ├── PROJECT_WISDOM.md (accumulated knowledge)
│   ├── TODO.md (task list)
│   └── *_LOG*.md (session logs)
```

## Three Implementations

1. **pc_prototype.sh** - Basic context switching (MVP)
2. **pc_enhanced.sh** - Adds git-inspired features (stash, diff, log)
3. **pc_unified_prototype.sh** - Full system with SQLite todos and GitHub integration

## Origin Story

This project emerged from a real pain point: working on multiple projects led to massive log files (66KB+) that slowed down LLM context loading. The solution evolved from simple log management to comprehensive project context management.

## Documentation

- [Git Context Insights](GIT_CONTEXT_INSIGHTS.md) - How git patterns apply to context management
- [GitHub Context Insights](GITHUB_CONTEXT_INSIGHTS.md) - Integration with GitHub's collaboration model
- [Unified Context Plan](UNIFIED_CONTEXT_PLAN.md) - Complete architectural vision
- [Log Management Guide](LOG_MIGRATION_GUIDE.md) - Managing large documentation files

## Future Enhancements

- [ ] GitHub wiki integration for shared knowledge
- [ ] Editor state preservation (open files, cursor positions)
- [ ] Terminal state restoration (directory, environment)
- [ ] Project templates for common setups
- [ ] Team collaboration features

## Contributing

Contributions are welcome! The codebase is intentionally simple (bash scripts) to encourage contributions and modifications.

## License

Licensed under either of

 * Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
 * MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.

## Author

Jack - Solving real developer workflow problems, one context at a time.