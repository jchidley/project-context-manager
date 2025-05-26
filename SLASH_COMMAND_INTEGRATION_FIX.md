# Slash Command Integration Fix

## Problem Identified

The slash commands (/start, /checkpoint, etc.) and the project context manager (pc) are not integrated properly:

### Current Issues
1. **Different Storage Locations**:
   - Slash commands expect files in current project directory
   - `pc` stores contexts in `~/.project-contexts/`
   - Planning docs are in project directory but not linked to context

2. **Different Todo Systems**:
   - Slash commands look for `todo.md` files
   - `pc` uses SQLite database at `~/.project-contexts/todos.db`
   - No integration between the two systems

3. **Discovery Failures**:
   - `/start` doesn't find TODO.md, PROJECT_WISDOM.md, or planning docs
   - `/checkpoint` doesn't update the context in `~/.project-contexts/`
   - No awareness of `pc` command capabilities

4. **HANDOFF.md Limitations** (Discovered 2025-01-26):
   - `/start` only reads HANDOFF.md, not other planning documents
   - User had to manually update HANDOFF.md to include "Key Files to Read"
   - Without explicit pointers, critical context gets missed
   - This is a design flaw that needs addressing in v0.2.0

## Root Cause

The slash commands were designed before the project context manager existed. They assume a simple file-based workflow, while `pc` provides a more sophisticated context management system.

## Solution Approach

### Option 1: Update Slash Commands (Recommended)
Modify slash commands to be `pc`-aware:

```markdown
# In /start command:
1. Check if `pc` is installed
2. If yes, use `pc status` to get current context
3. Load HANDOFF.md from both:
   - Current directory (traditional)
   - `~/.project-contexts/{context}/` (pc managed)
4. For todos, check both:
   - Local TODO.md file
   - `pc todo list` output
```

### Option 2: Sync Mechanism
Create a sync between pc contexts and local files:

```bash
# New pc command
pc sync-local  # Copies context files to current directory
pc sync-remote # Copies local files to context directory
```

### Option 3: Hybrid Approach
Keep both systems but make them aware of each other:

1. Slash commands check for `.pc-context` marker file
2. If found, delegate to `pc` commands
3. If not found, use traditional file approach

## Immediate Fix (Workaround)

Until proper integration is implemented:

```bash
# Create symlinks in project directory
ln -s ~/.project-contexts/.active/HANDOFF.md ./HANDOFF_PC.md
ln -s ~/.project-contexts/todos.db ./todos.db

# Update CLAUDE.md to mention both systems
```

## Proposed Changes

### 1. Update /start Command
```markdown
# Add to /start command logic:
- Check for `pc` installation: `command -v pc`
- If available, show: `pc status` and `pc todo list`
- Load HANDOFF.md from multiple locations
- Mention planning docs if found: TODO.md, PROJECT_WISDOM.md
```

### 2. Update /checkpoint Command
```markdown
# Add to /checkpoint command:
- If `pc` available, update both:
  - Local HANDOFF.md (traditional)
  - Context HANDOFF.md via `pc save`
- Sync PROJECT_WISDOM.md to context if exists
```

### 3. Create /pc-status Command
New command that shows unified view:
- Current pc context
- SQLite todos
- Local planning documents
- Git status
- Recent logs

## Testing Plan

1. Test /start with pc context active
2. Test /checkpoint updating both locations
3. Verify todo discovery from both sources
4. Ensure backward compatibility

## Long-term Vision

Eventually, slash commands should fully delegate to `pc` when available, providing a seamless experience while maintaining backward compatibility for users without `pc` installed.