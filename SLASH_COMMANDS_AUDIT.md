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
They were likely added as a command pack or workflow system:

### Likely Added by User (created after May 22)
- `/checkpoint` - Quick state capture during work
- `/log` - Document current session
- `/review-status` - Review project status
- `/start` - Begin or continue work session
- `/tool` - Tool-related functionality
- `/update-project` - Update project information
- `/wrap-session` - End work session

### Likely Part of a Command Pack (created May 22)
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

## Key Observations

1. **None of the custom commands match the default Claude Code commands** - they're completely separate systems

2. **The custom commands form a workflow**:
   - Planning: `/plan`, `/plan-tdd`, `/plan-gh`
   - Execution: `/do-todo`, `/do-issues`, `/do-plan`
   - Session Management: `/start`, `/checkpoint`, `/wrap-session`, `/log`
   - GitHub Integration: `/gh-issue`, `/make-github-issues`

3. **Integration Issues**:
   - Custom commands expect files (todo.md, plan.md, issues.md)
   - Project Context Manager uses different storage
   - No awareness between the two systems

4. **Command Sources**:
   - Default Claude Code: Built into the application
   - Custom commands: Added to ~/.claude/commands/
   - May 22 batch: Possibly from a shared command pack
   - Later additions: User-specific workflow commands