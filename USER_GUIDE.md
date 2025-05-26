# Project Context Manager - User Guide

## Table of Contents
- [Introduction](#introduction)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Core Concepts](#core-concepts)
- [Commands Reference](#commands-reference)
- [Workflows](#workflows)
- [Integration with Claude Code](#integration-with-claude-code)
- [Troubleshooting](#troubleshooting)

## Introduction

Project Context Manager (`pc`) helps developers maintain context when switching between multiple projects. It saves your working state, todos, and project knowledge in plain text files that both humans and LLMs can edit.

### Why Use PC?

- **Never lose context** when switching projects
- **Plain text storage** - edit with any tool
- **Git-aware** - respects your version control
- **LLM-friendly** - works with Claude Code and other AI tools
- **Zero dependencies** - just bash

## Installation

### Quick Install

```bash
git clone https://github.com/jchidley/project-context-manager.git
cd project-context-manager
./install.sh
```

### Manual Install

```bash
# Copy the script
cp pc.sh ~/.local/bin/pc
chmod +x ~/.local/bin/pc

# Add to PATH if needed
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

### Shell Completions

The installer adds completions automatically. To enable manually:

**Bash:**
```bash
source ~/.bash_completion.d/pc
```

**Zsh:**
```bash
fpath=(~/.zsh/completions $fpath)
autoload -U compinit && compinit
```

## Quick Start

### 1. Start with a Project

```bash
cd ~/my-project
pc switch my-project
```

### 2. Add Some Todos

```bash
pc todo add "Implement user authentication"
pc todo add "Write unit tests"
pc todo list
```

### 3. Save Your Work State

Create a `HANDOFF.md` file describing where you are:
```markdown
# Current Work
Working on user auth - implemented login, need to add logout
Next: Write tests for auth module
```

Then save:
```bash
pc save
```

### 4. Switch to Another Project

```bash
cd ~/other-project
pc switch other-project
# Your my-project context is safely stored!
```

### 5. Come Back Later

```bash
cd ~/my-project
pc switch my-project
pc status
# All your context is restored!
```

## Core Concepts

### Contexts

A **context** is a saved state for a project, including:
- `HANDOFF.md` - Current work state and next steps
- `TODO.md` - Task list in markdown format
- `PROJECT_WISDOM.md` - Accumulated knowledge and decisions
- `*_LOG_*.md` - Session logs and history

### Storage Structure

```
~/.project-contexts/
├── .active -> current_project      # Symlink to active context
├── project-name/
│   ├── HANDOFF.md
│   ├── TODO.md
│   ├── PROJECT_WISDOM.md
│   └── SESSION_001.md
└── another-project/
    └── ...
```

### Plain Text Philosophy

All data is stored in markdown files that can be:
- Edited with any text editor
- Versioned with git
- Read by LLMs (Claude, GPT, etc.)
- Grep'd, diff'd, and processed with Unix tools

## Commands Reference

### Context Management

#### `pc switch <context> [--force]`
Switch to a different context. Saves current work and restores the target context.

```bash
pc switch frontend-rewrite
pc switch backend-api --force  # Skip git dirty check
```

#### `pc status`
Show current context status, todos, and recent files.

```bash
$ pc status
Current context: my-project

Git status:
 M src/auth.js

=== Todos for my-project ===
- [ ] Implement logout
- [ ] Write auth tests
Summary: 2 todo, 0 in progress, 1 done

Context files:
  HANDOFF.md         1270  2025-05-26 14:29
  TODO.md             455  2025-05-26 14:30
```

#### `pc list`
List all available contexts.

```bash
$ pc list
Available contexts:
  frontend-rewrite (active) - 5 todos, 2 done
  backend-api - 3 todos, 0 done
  documentation - 0 todos, 0 done
```

#### `pc save`
Save current work files to the active context.

#### `pc restore [--force]`
Restore context files to working directory.

### Todo Management

#### `pc todo add <text>`
Add a new todo item.

```bash
pc todo add "Fix login redirect bug"
pc todo add "Update API documentation"
```

#### `pc todo list [filter]`
List todos with optional filter.

```bash
pc todo list          # All todos
pc todo list todo     # Only uncompleted
pc todo list done     # Only completed
```

#### `pc todo complete <pattern>`
Mark a todo as complete by matching pattern.

```bash
pc todo complete "login"    # Completes "Fix login redirect bug"
pc todo complete "API"      # Completes "Update API documentation"
```

### Git-Style Commands

#### `pc stash [save|pop|list]`
Temporarily save context without switching.

```bash
pc stash                # Save current state
pc stash pop           # Restore most recent stash
pc stash list          # Show all stashes
```

#### `pc diff <context>`
Compare current context with another.

```bash
pc diff production
# Shows differences in HANDOFF.md, TODO.md, etc.
```

#### `pc log`
Show recent context operations.

```bash
pc log
# 2025-05-26 14:30:15 | jack | /home/jack/project | pc switch my-project
# 2025-05-26 14:31:42 | jack | /home/jack/project | pc todo add "Fix bug"
```

## Workflows

### Daily Development Flow

1. **Morning Start**
   ```bash
   pc switch my-project
   pc status              # See where you left off
   cat HANDOFF.md        # Read detailed state
   ```

2. **During Work**
   ```bash
   pc todo add "New task discovered"
   pc todo complete "bug"
   # Edit TODO.md directly for complex updates
   ```

3. **End of Day**
   ```bash
   # Update HANDOFF.md with current state
   echo "## Today's Progress
   - Fixed auth bug
   - Started on logout
   
   ## Next Session
   - Finish logout implementation" > HANDOFF.md
   
   pc save
   ```

### Context Switching

When you need to quickly switch projects:

```bash
# Current project has uncommitted changes
$ pc switch urgent-fix
Warning: You have uncommitted changes
 M src/important.js
Commit or stash changes before switching
Use 'pc switch urgent-fix --force' to switch anyway

# Option 1: Commit your work
$ git add -A && git commit -m "WIP: auth feature"
$ pc switch urgent-fix

# Option 2: Stash with pc
$ pc stash
$ pc switch urgent-fix
# ... work on urgent fix ...
$ pc switch my-project
$ pc stash pop
```

### Project Templates

Create template contexts for common project types:

```bash
# Create a template
pc switch template-rails-api
echo "# Rails API Project

## Setup
- [ ] bundle install
- [ ] rails db:create
- [ ] rails db:migrate

## Standard Tasks
- [ ] Add authentication
- [ ] Setup CI/CD
- [ ] Write API docs" > TODO.md
pc save

# Use template for new project
pc switch new-api
cp ~/.project-contexts/template-rails-api/* ~/.project-contexts/new-api/
pc restore
```

## Integration with Claude Code

### Seamless TODO Management

Since v0.2.0, PC uses plain text TODO.md files that Claude Code can directly edit:

1. **Human edits TODO.md**
   ```bash
   vim TODO.md
   # Add, edit, complete todos manually
   pc save
   ```

2. **Claude Code edits TODO.md**
   ```
   /do-todo
   # Claude reads TODO.md and can mark items complete
   ```

3. **Both stay in sync**
   ```bash
   pc todo list  # Shows all changes from both human and LLM
   ```

### Slash Command Workflows

PC complements Claude Code's slash commands:

```bash
# Start new session
pc switch my-feature
/start

# Work with Claude
/plan                  # Creates plan.md
pc todo add "Implement features from plan.md"

# Save session
/wrap-session         # Creates session log
pc save              # Saves all context files
```

### Best Practices with LLMs

1. **Keep HANDOFF.md Updated**
   - Write clear "Current State" section
   - List specific next steps
   - Include blockers or decisions needed

2. **Use Descriptive Todos**
   ```markdown
   ## To Do
   - [ ] Refactor auth.js to use JWT tokens (see RFC 7519)
   - [ ] Add rate limiting to /api/login endpoint (max 5/minute)
   ```

3. **Document Decisions**
   ```markdown
   # PROJECT_WISDOM.md
   
   ## Architecture Decisions
   - Chose JWT over sessions for stateless API
   - Rate limiting uses Redis for distributed counts
   ```

## Troubleshooting

### Common Issues

**"No active context"**
```bash
# Fix: Create or switch to a context
pc switch my-project
```

**"Commit or stash changes before switching"**
```bash
# Fix: Handle git changes
git stash        # Or commit changes
pc switch other  # Now works
```

**"TODO.md exists in working directory"**
```bash
# Fix: Force restore if you want to overwrite
pc restore --force
```

### File Sync Issues

If your local files get out of sync:

```bash
# Save local changes
pc save

# Or restore from context
pc restore --force

# Compare differences
pc diff my-project
```

### Migration from v0.1.0

If upgrading from SQLite version:

```bash
# Run migration script
./migrate_todos_to_plain_text.sh

# Install new version
./install.sh

# Verify todos migrated
pc todo list
```

## Advanced Usage

### Custom Context Locations

```bash
# Use different storage location
export PC_HOME="$HOME/Dropbox/contexts"
pc switch shared-project
```

### Git Hooks Integration

Add to `.git/hooks/post-checkout`:
```bash
#!/bin/bash
# Auto-switch context on branch change
branch=$(git branch --show-current)
pc switch "$branch" 2>/dev/null || true
```

### Team Workflows

Share contexts via git:

```bash
# In project repo
mkdir .contexts
cd .contexts
git init
pc switch team-project
ln -s ~/.project-contexts/team-project/* .
git add -A && git commit -m "Share context"
```

---

For more information:
- GitHub: https://github.com/jchidley/project-context-manager
- Issues: https://github.com/jchidley/project-context-manager/issues