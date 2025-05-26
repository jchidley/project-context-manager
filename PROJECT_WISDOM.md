# PROJECT WISDOM: Project Context Manager

## Active Insights

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