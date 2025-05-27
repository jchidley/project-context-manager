# Claude Project Setup Guide

This guide provides a comprehensive approach for organizing programming projects to enable uninterrupted Claude work, covering both new projects and significant changes to existing ones.

## Essential Documents for Claude-Ready Projects

### 1. **CLAUDE.md** (Project Instructions)
This is your primary directive file. Structure it with:
```markdown
# CLAUDE.md

## Project Purpose
[One paragraph describing what this project does and why]

## Architecture Overview
[Key components, data flow, critical design decisions]

## Technical Stack
- Language: [e.g., Rust, Python with uv, TypeScript with Bun]
- Framework: [e.g., Axum, FastAPI, SvelteKit]
- Database: [e.g., SQLite at ~/.local/share/projectname/]
- External Services: [APIs, auth providers, etc.]

## Development Workflow
### Essential Commands
```bash
# Build/Run
mask build
mask test
mask lint

# Development
mask dev
mask watch
```

## Project Structure
[Explain non-obvious directory/file organization]

## Key Implementation Details
[Critical functions, patterns, gotchas]

## Constraints & Requirements
- Must support [specific features]
- Performance: [targets]
- Security: [considerations]
```

### 2. **REQUIREMENTS.md** (For New Projects)
```markdown
# Requirements

## User Interface
### Primary Views
- [View Name]: [Purpose and key elements]

### User Flows
1. [Flow name]: Step-by-step interaction

## Core Functionality
### Must Have (MVP)
- [ ] Feature 1: [Description]
- [ ] Feature 2: [Description]

### Should Have
- [ ] Feature 3: [Description]

### Nice to Have
- [ ] Feature 4: [Description]

## Technical Requirements
### Performance
- Response time: < 200ms
- Concurrent users: 100+

### Data Requirements
- Storage: [estimates]
- Retention: [policies]

## External Integrations
- Service A: [purpose, API details]
- Service B: [authentication method]
```

### 3. **HANDOFF.md** (Work State)
```markdown
# Current State

## What I Was Doing
[Last task/feature being worked on]

## Next Steps
1. [Immediate next action]
2. [Following action]

## Current Blockers
- [Issue description and what's needed]

## Recent Decisions
- Chose X over Y because [reasoning]
```

### 4. **maskfile.md** (Task Automation)
```markdown
## setup
> Initial project setup

~~~bash
uv sync
pre-commit install
~~~

## test
> Run all tests

~~~bash
set -e
uv run pytest
~~~

## dev
> Start development server

~~~bash
uvx --with watchdog watchmedo auto-restart --patterns="*.py" -- uv run python main.py
~~~
```

### 5. **TODO.md** (Task Tracking)
```markdown
# TODO

## In Progress
- [ ] Implement user authentication
  - [x] Database schema
  - [ ] Login endpoint
  - [ ] Session management

## Backlog
- [ ] Add rate limiting
- [ ] Implement caching layer
```

## Workflow for Different Scenarios

### New Project Setup
```bash
# 1. Create project structure
mkdir -p ~/projects/newproject
cd ~/projects/newproject

# 2. Initialize with context manager
pc init newproject

# 3. Create essential docs
cat > CLAUDE.md << 'EOF'
# CLAUDE.md
## Project Purpose
[Your description]
EOF

cat > REQUIREMENTS.md << 'EOF'
# Requirements
[Your requirements]
EOF

# 4. Set up task runner
cat > maskfile.md << 'EOF'
## init
> Initialize project
~~~bash
[setup commands]
~~~
EOF

# 5. Start Claude with clear directive
# "Implement the requirements in REQUIREMENTS.md following the constraints in CLAUDE.md"
```

### Significant Change to Existing Project
```bash
# 1. Switch context
pc switch projectname

# 2. Update REQUIREMENTS.md with new section
cat >> REQUIREMENTS.md << 'EOF'

## Phase 2 Requirements
### New Features
- [ ] Feature X: [description]
EOF

# 3. Create migration plan
cat > MIGRATION_PLAN.md << 'EOF'
# Migration to [New Feature]

## Current State
[What exists now]

## Target State
[What we're building]

## Migration Steps
1. [Non-breaking preparation]
2. [Core changes]
3. [Cleanup]
EOF

# 4. Clear handoff for Claude
# "Implement Phase 2 requirements following MIGRATION_PLAN.md"
```

## Key Success Factors

1. **Explicit Context**: Never assume Claude remembers previous conversations
2. **Self-Contained Tasks**: Each work session should have clear start/end goals
3. **Verification Steps**: Always include "mask test" or similar in requirements
4. **Progressive Enhancement**: Structure changes as non-breaking additions first

## Integration with Project Context Manager

The `pc` tool is designed to work seamlessly with this structure:

```bash
# Initialize a new project with context
pc init myproject

# Switch to a project (restores HANDOFF.md, TODO.md, etc.)
pc switch myproject

# Save current work state before switching
pc stash "implementing auth"

# View all projects and their states
pc list

# Archive completed work to logs
pc log "Completed authentication feature"
```

## Best Practices

### For New Projects
1. Start with REQUIREMENTS.md to clarify what you're building
2. Create CLAUDE.md with technical decisions and constraints
3. Use `pc init` to establish context management from day one
4. Set up maskfile.md for repeatable tasks

### For Existing Projects
1. Document current architecture in CLAUDE.md first
2. Use MIGRATION_PLAN.md for significant changes
3. Keep HANDOFF.md updated with current work state
4. Archive completed work with `pc log` to maintain context

### For Long-Running Sessions
1. Break work into clear phases with explicit success criteria
2. Use TODO.md to track progress within each phase
3. Regular commits with descriptive messages
4. Update HANDOFF.md before ending each session

This approach minimizes interruptions by providing Claude with complete context upfront and clear success criteria.