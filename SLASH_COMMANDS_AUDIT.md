# Slash Commands Audit

## Default Claude Code Commands (Built-in)
According to the official documentation, these are the built-in commands that run Claude Code functions:
- `/bug` - Report bugs
- `/clear` - Clear conversation history
- `/compact` - Compact conversation
- `/config` - View/modify configuration
- `/cost` - Show token usage statistics
- `/doctor` - Check Claude Code installation health
- `/help` - Get usage help
- `/init` - Initialize project with CLAUDE.md
- `/login` - Switch Anthropic accounts
- `/logout` - Sign out
- `/memory` - Edit CLAUDE.md files
- `/model` - Select AI model
- `/pr_comments` - View PR comments
- `/review` - Request code review
- `/status` - View account status
- `/terminal-setup` - Install key binding
- `/vim` - Enter vim mode

## Custom Commands in ~/.claude/commands/
All 23 files in this directory are custom prompt templates, NOT default Claude Code commands.

### Commands Added by Claude Code Installation (May 22, 2025)
These 16 commands were installed with Claude Code:
- `/brainstorm` - Brainstorming session
- `/do-file-issues` - Work through file issues
- `/do-issues` - Work through issues.md
- `/do-plan` - Execute plan
- `/do-prompt-plan` - Execute prompt plan
- `/do-todo` - Execute tasks from todo.md
- `/find-missing-tests` - Identify untested code
- `/gh-issue` - Create GitHub issue
- `/make-github-issues` - Convert to GitHub issues
- `/make-local-issues` - Create local issues
- `/plan` - Create project plan
- `/plan-gh` - Plan with GitHub integration
- `/plan-tdd` - Plan with TDD approach
- `/security-review` - Review security
- `/session-summary` - Summarize session
- `/setup` - Project setup

### User-Created Commands (Author: Jack Chidley)
These 7 commands were created for session management workflow:
- `/checkpoint` - Quick state capture during work (Created: 2025-05-25)
- `/log` - Document current session (Created: 2025-05-23)
- `/review-status` - Review project status (Created: 2025-05-25)
- `/start` - Begin or continue work session (Created: 2025-05-25)
- `/tool` - Tool-related functionality (Created: 2025-05-25)
- `/update-project` - Update project information (Created: 2025-05-25)
- `/wrap-session` - End work session (Created: 2025-05-25)

## Key Observations

1. **Three Distinct Command Types**:
   - **Built-in Claude Code**: Application functions (/help, /model, etc.)
   - **Claude Code Templates**: Installed prompt templates for planning/execution
   - **User Session Commands**: Custom workflow for state management

2. **Command Workflows**:
   
   **Claude Code Template Workflow** (plan → execute):
   - Planning: `/plan`, `/plan-tdd`, `/plan-gh` → creates plan.md
   - Execution: `/do-todo`, `/do-plan`, `/do-issues` → reads todo.md/plan.md
   - Testing: `/find-missing-tests`, `/security-review`
   - GitHub: `/gh-issue`, `/make-github-issues`
   
   **User Session Workflow** (start → work → checkpoint → wrap):
   - `/start` → Begin session, load HANDOFF.md
   - `/checkpoint` → Save progress to HANDOFF.md
   - `/log` → Document session details
   - `/wrap-session` → Archive and prepare for next session

3. **File Expectations**:
   - Claude Code templates expect: todo.md, plan.md, issues.md (lowercase)
   - User commands expect: HANDOFF.md, PROJECT_WISDOM.md (uppercase)
   - Both expect plain text files in project directory

4. **Integration Challenge**:
   - Project Context Manager uses SQLite + different directory structure
   - Custom commands expect plain text files in current directory
   - No awareness between pc tool and slash commands