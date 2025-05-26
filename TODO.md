# TODO - project-context-manager

Last updated: 2025-05-26 14:50

## In Progress - v0.2.0 Plain Text Migration

- [x] Export existing SQLite todos to TODO.md format <!-- completed:2025-05-26 14:18 -->
- [x] Implement plain text todo operations (add, complete, list) <!-- completed:2025-05-26 14:26 -->
- [x] Update all pc commands to use plain text <!-- completed:2025-05-26 14:30 -->
- [x] Create migration script for existing users <!-- completed:2025-05-26 14:18 -->
- [x] Rename files to remove _v2 suffix <!-- completed:2025-05-26 14:40 -->
- [x] Update install script to be more generic <!-- completed:2025-05-26 14:40 -->
- [x] Test with both human and LLM workflows <!-- completed:2025-05-26 14:55 -->
- [ ] Update documentation for plain text format
- [ ] Fix /start command to auto-discover key files (TODO.md, PROJECT_WISDOM.md)
- [ ] Make HANDOFF.md auto-include pointers to related docs
- [ ] Release v0.2.0 with migration guide

## To Do

- [ ] Add README badges - version and license <!-- created:2025-05-26 12:37:01 -->
- [ ] Set up CI/CD with GitHub Actions <!-- created:2025-05-26 12:37:07 -->
- [ ] Create comprehensive user guide
- [ ] Add shell completion scripts
- [ ] Implement session-based logging (from LOG_MANAGEMENT_TODO.md)

## Testing Human Workflow

- [ ] Test human workflow - editing TODO.md directly <!-- created:2025-05-26 14:37 -->
- [x] Human can mark this as complete by changing [ ] to [x] <!-- completed:2025-05-26 14:50 -->