# Project Context Manager - TODO

## Current Status
- ✅ Phase 1: Core Context Manager (COMPLETE - v0.1.0 released)
  - Basic switch/save/restore
  - Git-aware (check dirty state)
  - Non-destructive operations
  - Stash functionality

## Phase 2: Work Item Management (IN PROGRESS)
- [x] Persistent todos across contexts (SQLite implementation done)
- [ ] Todo labels and milestones
- [ ] Cross-context todo search (basic version exists with --all)
- [ ] Todo dependencies
- [ ] Better todo formatting and filtering

## Phase 3: GitHub Integration (NEXT)
- [ ] Link todos to GitHub issues (basic linking exists)
- [ ] Create issues from todos with `pc todo add --issue`
- [ ] Sync status bidirectionally
- [ ] PR-based context creation
- [ ] Full `gh` CLI integration for seamless workflow

## Phase 4: Knowledge Management
- [ ] Wiki for shared knowledge
- [ ] Discussions for decisions
- [ ] Templates for contexts
- [ ] Search across everything

## Immediate Improvements (v0.2.0 candidates)
- [ ] Add README badges (version, license)
- [ ] Set up CI/CD for testing
- [ ] Create shell completion scripts
- [ ] Add `pc init --template` for common project types
- [ ] Improve error messages and help text
- [ ] Add `pc archive` command for old contexts
- [ ] Create installation script

## Log Management Specific
- [ ] Implement session-based logging (from LOG_MANAGEMENT_TODO.md)
- [ ] Create /log command improvements
- [ ] Add log rotation and summarization
- [ ] Hierarchical log structure when >5KB

## Documentation
- [ ] Create comprehensive user guide
- [ ] Add examples directory with workflows
- [ ] Video/GIF demos for README
- [ ] Migration guide from other tools