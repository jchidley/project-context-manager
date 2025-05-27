# Project Context Manager (pc)

[![GitHub release](https://img.shields.io/github/v/release/jchidley/project-context-manager)](https://github.com/jchidley/project-context-manager/releases)
[![License](https://img.shields.io/badge/license-MIT%2FApache--2.0-blue)](LICENSE-MIT)

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

# Manage todos in plain text (v0.2.0+)
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
- **Plain Text Todos**: Human and LLM-editable TODO.md files (v0.2.0+)
- **Claude-Ready Projects**: Enhanced init creates full AI-assisted dev setup (v0.2.3+)
- **Claude Code Integration**: Works seamlessly with slash commands
- **GitHub Integration**: Optional two-way sync with GitHub issues
- **Non-Destructive**: Automatic backups before operations
- **Human-Readable**: All state stored in markdown files

## Installation

```bash
# Clone the repository
git clone https://github.com/jchidley/project-context-manager.git
cd project-context-manager

# Install latest version (v0.2.2 - refactored & tested)
./install.sh

# Or manual installation
cp pc_refactored.sh ~/.local/bin/pc
chmod +x ~/.local/bin/pc
```

## Quick Start

```bash
# Create a new Claude-ready project
pc init my-project              # Creates subdirectory ./my-project
pc init my-project .            # Initialize in current directory
pc init my-project ~/projects   # Initialize in specific directory

# Or work with existing project
cd ~/my-project
pc switch my-project

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
├── .todos.db (SQLite database - v0.1.0 only)
├── project-name/
│   ├── HANDOFF.md (current state)
│   ├── PROJECT_WISDOM.md (accumulated knowledge)
│   ├── TODO.md (task list - plain text in v0.2.0+)
│   └── *_LOG*.md (session logs)
```

## Upgrading from v0.1.0

If you have existing SQLite todos:

```bash
git checkout v0.2.0-plain-text-migration
./migrate_todos_to_plain_text.sh
./install.sh
```

Your todos will be converted to plain text TODO.md files in each context.

## Origin Story

This project emerged from a real pain point: working on multiple projects led to massive log files (66KB+) that slowed down LLM context loading. The solution evolved from simple log management to comprehensive project context management.

## Documentation

- **[User Guide](USER_GUIDE.md)** - Comprehensive guide with examples and workflows
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