# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Project Context Manager (pc) - A developer tool for managing context across multiple concurrent projects. Solves the problem of losing mental state and LLM context files (HANDOFF.md, PROJECT_WISDOM.md, logs) when switching between projects.

## Architecture Overview

### Core Design Pattern
The system separates three types of state:
- **Code State** (managed by git): Source files and version control
- **Work State** (managed by pc): Todos, handoffs, logs, and project wisdom
- **Meta State** (managed by GitHub): Issues, projects, and collaboration

### Storage Structure
```
~/.project-contexts/
├── .active -> current_project (symlink to active context)
├── .todos.db (SQLite database for persistent todos)
├── .stash/ (temporary context saves)
├── .backups/ (automatic backups before operations)
├── .history (command history log)
├── project-name/
│   ├── HANDOFF.md (current work state)
│   ├── PROJECT_WISDOM.md (accumulated knowledge)
│   ├── TODO.md (task list)
│   └── *_LOG*.md (archived session logs)
```

## Essential Commands

### Development & Testing
```bash
# No build process - these are bash scripts
# Test by running directly:
./pc_prototype.sh status
./pc_enhanced.sh status
./pc_unified_prototype.sh status

# Install for local use:
cp pc_unified_prototype.sh ~/.local/bin/pc
chmod +x ~/.local/bin/pc

# Check for syntax errors:
bash -n pc_*.sh

# Debug mode (most scripts support):
DEBUG=1 ./pc_unified_prototype.sh status
```

### Script Evolution
Three implementations with increasing sophistication:
1. **pc_prototype.sh** - Basic context switching (MVP)
2. **pc_enhanced.sh** - Adds git-inspired features (stash, diff, log)
3. **pc_unified_prototype.sh** - Full system with SQLite todos and GitHub integration

## Key Implementation Details

### Database Schema (SQLite)
The unified prototype uses `.todos.db` with schema:
- todos table: id, context, title, description, status, github_issue_number, created_at, updated_at
- Supports cross-context queries and GitHub issue linking

### Critical Functions
- `ensure_context_dir()` - Creates storage structure
- `save_current_files()` - Non-destructive file operations
- `create_backup()` - Automatic safety backups
- `sync_github_issues()` - Two-way GitHub synchronization

### Git Integration Points
- Checks for uncommitted changes before context switch
- Optionally runs `git stash` during context operations
- Records current git branch with context metadata
- Preserves git state awareness across switches

## Design Decisions

### Why Bash?
- Zero dependencies for maximum portability
- Direct filesystem operations without abstraction layers
- Easy installation (single file copy)
- Transparent operations users can understand

### Session-Based Log Management
- Archives based on work sessions, not calendar time
- Prevents single massive log file (original 66KB+ problem)
- Hierarchical summaries keep active context small (<5KB)

### Local-First Architecture
- Full functionality without network
- Optional GitHub integration
- SQLite for persistent data (todos)
- Filesystem for context files

## Future Enhancements (from planning docs)

### Planned Features
- GitHub wiki/knowledge base integration
- Editor state preservation (open files, cursor positions)
- Terminal state restoration (working directory, environment)
- Team collaboration features
- Project templates

### Migration Path
Current bash implementation designed to establish UX patterns before potential Rust rewrite for performance and distribution.