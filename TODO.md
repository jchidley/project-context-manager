# TODO - project-context-manager

Last updated: 2025-05-26 17:35

## Completed - v0.2.0 Plain Text Migration

- [x] Export existing SQLite todos to TODO.md format <!-- completed:2025-05-26 14:18 -->
- [x] Implement plain text todo operations (add, complete, list) <!-- completed:2025-05-26 14:26 -->
- [x] Update all pc commands to use plain text <!-- completed:2025-05-26 14:30 -->
- [x] Create migration script for existing users <!-- completed:2025-05-26 14:18 -->
- [x] Rename files to remove _v2 suffix <!-- completed:2025-05-26 14:40 -->
- [x] Update install script to be more generic <!-- completed:2025-05-26 14:40 -->
- [x] Test with both human and LLM workflows <!-- completed:2025-05-26 14:55 -->
- [x] Update documentation for plain text format <!-- completed:2025-05-26 15:00 -->
- [x] Release v0.2.0 with migration guide <!-- completed:2025-05-26 15:10 -->

## Completed - Future Enhancements (2025-05-26)

- [x] Fix /start command to auto-discover key files (TODO.md, PROJECT_WISDOM.md) <!-- completed:2025-05-26 17:15 -->
- [x] Make HANDOFF.md auto-include pointers to related docs <!-- completed:2025-05-26 17:25 -->
- [x] Add todo section detection (In Progress, To Do, Done) with `pc todo progress` <!-- completed:2025-05-26 17:35 -->

## To Do

- [x] Add README badges - version and license <!-- completed:2025-05-26 15:20 -->
- [x] Set up CI/CD with GitHub Actions <!-- completed:2025-05-26 15:25 -->
- [x] Create comprehensive user guide <!-- completed:2025-05-26 15:55 -->
- [x] Add shell completion scripts <!-- completed:2025-05-26 15:30 -->
- [x] Implement session-based logging <!-- completed:2025-05-26 16:00 -->

## Testing Human Workflow

- [ ] Test human workflow - editing TODO.md directly <!-- created:2025-05-26 14:37 -->
- [x] Human can mark this as complete by changing [ ] to [x] <!-- completed:2025-05-26 14:50 -->