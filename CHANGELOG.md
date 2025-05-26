# Changelog

All notable changes to the Project Context Manager will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1] - 2025-05-26

### Added
- Auto-discovery of key files in /start command (TODO.md, PROJECT_WISDOM.md, etc.)
- Related Documents section in HANDOFF.md for better context navigation
- `pc todo progress <pattern>` command to mark tasks as in-progress
- Support for "## In Progress" section in TODO.md files
- Session-based logging with `pc session` commands
- Comprehensive user guide (USER_GUIDE.md)
- GitHub Actions CI/CD workflows
- Shell completions for bash and zsh
- README badges for version and license

### Changed
- /start, /checkpoint, and /wrap-session slash commands now auto-discover project files
- Installation script now installs shell completions
- Todo list filter now supports "in-progress" option

### Enhanced
- Better integration between pc and Claude Code workflows
- Improved context loading for continuing work sessions

## [0.2.0] - 2025-05-26

### Changed
- **BREAKING**: Migrated from SQLite to plain text TODO.md files
- Todo storage now uses standard markdown format for better integration with Claude Code
- All todos are now directly editable in TODO.md files

### Added
- Plain text todo operations (add, complete, list)
- Git-style stash commands (stash, stash pop, stash list)
- Context diff command to compare contexts
- Migration script for existing SQLite users
- Installation script for easy upgrades

### Fixed
- Integration with Claude Code slash commands (/do-todo, /plan, etc.)
- Todo files can now be edited by both humans and LLMs

### Migration
Users upgrading from v0.1.0 should:
1. Run `./migrate_todos_to_plain_text.sh` to export SQLite todos
2. Run `./install_v2.sh` to install the new version
3. Review generated TODO.md files in each context directory

## [0.1.0] - 2025-01-26

### Added
- Initial release with core context management
- Git-aware context switching
- Non-destructive file operations
- SQLite-based todo management
- Stash functionality for temporary saves
- Context backup system
- Command history logging

### Features
- `pc switch` - Switch between project contexts
- `pc status` - Show current context and todos
- `pc list` - List all available contexts
- `pc save/restore` - Manage context files
- `pc todo` - Manage todos with SQLite backend