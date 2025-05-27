# TODO - project-context-manager

Last updated: 2025-05-27 15:34:02

## To Do - High Priority

- [ ] Fix grep -c bug in todo_commands.sh <!-- created:2025-05-26 21:20 -->
- [ ] Monitor community feedback and GitHub issues for v0.3.0 ideas <!-- created:2025-05-26 19:40 -->
- [x] Enhance pc init to create full Claude-ready project structure <!-- created:2025-05-27 15:00 --> <!-- completed:2025-05-27 -->

## To Do - Code Quality & Testing

- [ ] Add integration tests for main workflows <!-- created:2025-05-26 20:00 -->
- [ ] Fix remaining shellcheck warnings in library files <!-- created:2025-05-26 20:30 -->
- [ ] Test human workflow - editing TODO.md directly <!-- created:2025-05-26 14:37 -->

## To Do - v0.3.0 Feature Implementation

- [ ] Implement hierarchical log structure from HIERARCHICAL_LOG_ANALYSIS.md <!-- created:2025-05-26 20:45 -->
- [ ] Add pc commands to settings.local.json template per SETTINGS_LOCAL_RECOMMENDATION.md <!-- created:2025-05-26 20:45 -->
- [ ] GitHub wiki integration for shared knowledge bases <!-- created:2025-05-26 18:00 -->
- [ ] Terminal state restoration (working directory, environment) <!-- created:2025-05-26 18:00 -->
- [ ] Project templates for common setups <!-- created:2025-05-26 18:00 -->
- [ ] Team collaboration features <!-- created:2025-05-26 18:00 -->

## Completed - v0.2.2 Release Preparation (2025-05-27)

- [x] Align project structure with CLAUDE_PROJECT_SETUP_GUIDE.md recommendations <!-- completed:2025-05-27 09:35 -->
- [x] Create v0.2.2 release with refactored codebase <!-- completed:2025-05-27 09:45 -->

## Completed - Migration to Refactored Version (2025-05-26)

- [x] Migrate users from pc.sh to pc_refactored.sh <!-- completed:2025-05-26 21:15 -->

## Completed - Code Cleanup & Testing (2025-05-26)

- [x] Create common library file (lib/common.sh) for shared functions <!-- completed:2025-05-26 20:00 -->
- [x] Extract color definitions and formatting to lib/common.sh <!-- completed:2025-05-26 20:00 -->
- [x] Add input validation for context names and todo patterns <!-- completed:2025-05-26 20:00 -->
- [x] Create test framework using bats (Bash Automated Testing System) <!-- completed:2025-05-26 20:10 -->
- [x] Write unit tests for core functions (context switching, todo operations) <!-- completed:2025-05-26 20:15 -->
- [x] Create maskfile.md for test/lint/install tasks <!-- completed:2025-05-26 20:10 -->
- [x] Add shellcheck linting to all scripts <!-- completed:2025-05-26 20:20 -->
- [x] Fix shellcheck warnings in refactored code <!-- completed:2025-05-26 20:25 -->
- [x] Refactor pc.sh to be modular (<500 lines per file) <!-- completed:2025-05-26 20:20 -->
- [x] Add GitHub Actions CI/CD pipeline for automated testing <!-- completed:2025-05-26 20:40 -->

## Completed - v0.3.0 Planning & Analysis (2025-05-26)

- [x] Remove update-project.md slash command as it duplicates checkpoint/wrap-session functionality <!-- completed:2025-05-26 19:33 -->
- [x] Consider adopting hierarchical log structure from /log command for better log management <!-- completed:2025-05-26 19:40 -->
- [x] Add frequently used tools to settings.local.json (see ~/tools/.claude/settings.local.json) <!-- completed:2025-05-26 19:40 -->
- [x] Monitor community feedback and GitHub issues for v0.3.0 ideas <!-- completed:2025-05-26 19:40 -->

## Completed - Slash Command Analysis (2025-05-26)

- [x] Explore slash commands in ~/.claude/commands to see what they do, check for good ideas or duplication of effort. update-project.md might duplicate start/checkpoint/wrap-project and should be removed if so <!-- completed:2025-05-26 18:15 -->

## Completed - v0.2.1 Enhancements (2025-05-26)

- [x] Fix /start command to auto-discover key files (TODO.md, PROJECT_WISDOM.md) <!-- completed:2025-05-26 17:15 -->
- [x] Make HANDOFF.md auto-include pointers to related docs <!-- completed:2025-05-26 17:25 -->
- [x] Add todo section detection (In Progress, To Do, Done) with `pc todo progress` <!-- completed:2025-05-26 17:35 -->
- [x] Add README badges - version and license <!-- completed:2025-05-26 15:20 -->
- [x] Set up CI/CD with GitHub Actions <!-- completed:2025-05-26 15:25 -->
- [x] Create comprehensive user guide <!-- completed:2025-05-26 15:55 -->
- [x] Add shell completion scripts <!-- completed:2025-05-26 15:30 -->
- [x] Implement session-based logging <!-- completed:2025-05-26 16:00 -->

## Completed - v0.2.0 Plain Text Migration (2025-05-26)

- [x] Export existing SQLite todos to TODO.md format <!-- completed:2025-05-26 14:18 -->
- [x] Implement plain text todo operations (add, complete, list) <!-- completed:2025-05-26 14:26 -->
- [x] Update all pc commands to use plain text <!-- completed:2025-05-26 14:30 -->
- [x] Create migration script for existing users <!-- completed:2025-05-26 14:18 -->
- [x] Rename files to remove _v2 suffix <!-- completed:2025-05-26 14:40 -->
- [x] Update install script to be more generic <!-- completed:2025-05-26 14:40 -->
- [x] Test with both human and LLM workflows <!-- completed:2025-05-26 14:55 -->
- [x] Update documentation for plain text format <!-- completed:2025-05-26 15:00 -->
- [x] Release v0.2.0 with migration guide <!-- completed:2025-05-26 15:10 -->
- [x] Human can mark this as complete by changing [ ] to [x] <!-- completed:2025-05-26 14:50 -->