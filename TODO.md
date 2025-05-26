# Project Context Manager - TODO

## Current Status
- ✅ Phase 1: Core Context Manager (COMPLETE - v0.1.0 released)
  - Basic switch/save/restore
  - Git-aware (check dirty state)
  - Non-destructive operations
  - Stash functionality

## Completed Today
- [x] Created v0.1.0 release on GitHub
- [x] Documented slash command integration issues
- [x] Audited all slash commands (23 custom, 0 overlap with defaults)
- [x] Added author attribution to custom commands
- [x] Decided on plain text migration (SQLite → TODO.md)

## Immediate: v0.2.0 Plain Text Migration (CRITICAL)
- [ ] Create v0.2.0 branch
- [ ] Export existing SQLite todos to TODO.md format
- [ ] Implement plain text todo operations (add, complete, list)
- [ ] Update all pc commands to use plain text
- [ ] Fix /start command to auto-discover key files (TODO.md, PROJECT_WISDOM.md)
- [ ] Make HANDOFF.md auto-include pointers to related docs
- [ ] Create migration script for existing users
- [ ] Test with both human and LLM workflows
- [ ] Update documentation for plain text format
- [ ] Release v0.2.0 with migration guide

## Phase 2: Work Item Management (REDESIGNED)
- [x] ~~Persistent todos across contexts~~ → Moving to plain text
- [ ] Todo sections in TODO.md (High Priority, In Progress, Completed)
- [ ] Cross-context todo search using grep
- [ ] GitHub issue linking with #123 format
- [ ] Archive completed todos to history file

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