# PROJECT WISDOM: Project Context Manager

## Active Insights

### 2025-05-27: Project Structure Alignment  
Insight: Following CLAUDE_PROJECT_SETUP_GUIDE.md patterns dramatically improves Claude's ability to work uninterrupted
Impact: Created REQUIREMENTS.md and enhanced CLAUDE.md structure, enabling clearer project context and reducing ambiguity in work sessions

### 2025-05-27: Modular Refactoring Success
Insight: Breaking 1050-line script into ~500-line main + libraries improves maintainability without sacrificing functionality
Impact: Easier to test, extend, and debug - each module has single responsibility making changes safer

### 2025-01-26: First Release Milestone
Insight: Publishing v0.1.0 marks the transition from concept to usable tool
Impact: The project now has a stable reference point and can grow from user feedback rather than speculation

### 2025-01-26: SQL Bug Fix Importance
Insight: A single missing comma in SQL can break entire functionality
Impact: Reinforces the need for immediate testing of database operations, even in "simple" scripts

### 2025-01-26: GitHub CLI Integration
Insight: Using `gh release create` with heredoc for release notes provides clean, formatted releases
Impact: Enables rich release documentation without leaving the terminal, maintaining developer flow

### 2025-01-26: Plain Text > SQLite for Human/LLM Tools
Insight: SQLite creates barriers for both humans (can't edit directly) and LLMs (need bash commands)
Impact: Choosing plain text formats enables direct manipulation, git diffs, and seamless integration

### 2025-01-26: Integration Failures Reveal Architecture Flaws
Insight: Slash commands couldn't find todos because of SQLite/text split
Impact: When tools don't integrate naturally, the architecture might be wrong

### 2025-01-26: Command Origins Matter for Design
Insight: Claude Code ships with 16 planning/execution templates expecting plain text
Impact: Tools should align with existing ecosystem conventions, not fight them

### 2025-01-26: HANDOFF.md Needs Explicit Pointers
Insight: /start only reads HANDOFF.md, missing other critical planning documents
Impact: Had to manually add "Key Files to Read" section to ensure context loaded properly

### 2025-05-26: Test Coverage Prevents Regressions
Insight: Creating BATS tests revealed issues with readonly variables and missing functions
Impact: Automated testing catches problems before users do, enabling confident refactoring

### 2025-05-26: Shellcheck Compliance Improves Reliability
Insight: SC2155 warnings (declare and assign separately) can mask command failures
Impact: Following shellcheck recommendations makes scripts more robust and debuggable

### 2025-05-26: Modular Architecture Enables Clean Migration
Insight: Refactoring into lib/ modules made it easy to fix library paths during deployment
Impact: Separating concerns into common.sh, todo_commands.sh, and stash_commands.sh improves maintainability