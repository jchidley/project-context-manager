# Proposal: Migrate from SQLite to Plain Text TODOs

## Current Problem

The SQLite database creates friction:
- LLMs can't read/write todos without bash commands
- Humans can't edit todos in their text editor
- Git can't show meaningful diffs of todo changes
- Slash commands expect TODO.md files, not databases
- Violates "plain text is universal" principle

## Proposed Solution

Replace SQLite with structured markdown files that both humans and LLMs can manipulate directly.

### File Structure
```
~/.project-contexts/
├── project-name/
│   ├── TODO.md          # Plain text todos
│   ├── HANDOFF.md       # Current state
│   ├── PROJECT_WISDOM.md # Accumulated knowledge
│   └── LOGS/            # Session logs
```

### TODO.md Format
```markdown
# Project TODOs

## High Priority
- [ ] #123 Fix authentication bug @security
- [ ] Add user dashboard @feature

## In Progress  
- [~] #125 Refactor database queries @performance
  Started: 2025-01-26
  Notes: Optimizing N+1 queries

## Completed (Recent)
- [x] #122 Set up CI/CD pipeline @devops
  Completed: 2025-01-25
```

### Benefits

1. **LLM-friendly**: Direct file manipulation with Read/Write tools
2. **Human-friendly**: Edit in VSCode, vim, any text editor
3. **Git-friendly**: Clear diffs showing todo changes
4. **Slash command compatible**: Works with existing commands
5. **Zero dependencies**: Pure bash string manipulation
6. **Portable**: Copy files between systems easily

### Advanced Features Without SQLite

**Cross-context search:**
```bash
grep -r "\[ \]" ~/.project-contexts/*/TODO.md
```

**Filter by tag:**
```bash
grep "@security" ~/.project-contexts/*/TODO.md
```

**Count todos:**
```bash
grep -c "^- \[ \]" TODO.md
```

**Link to GitHub:**
```markdown
- [ ] #123 Fix auth bug  <!-- Links to issue #123 -->
```

### Migration Path

1. Export existing SQLite todos to TODO.md format
2. Update pc commands to use plain text operations
3. Remove SQLite dependency
4. Update documentation

### Implementation Example

```bash
# Add todo
echo "- [ ] $title @$tag" >> TODO.md

# Mark complete  
sed -i 's/\[ \] #123/\[x\] #123/' TODO.md

# List todos
grep "^- \[ \]" TODO.md

# Move to in-progress
sed -i 's/\[ \] #123/\[~\] #123/' TODO.md
```

## Decision Point

Should we proceed with this migration? The benefits seem to far outweigh the costs, especially given our user base (developers using LLMs) and our principles (plain text, git-friendly, simple).

## Next Steps (if approved)

1. Create migration script to export SQLite data
2. Implement plain text todo functions
3. Update all pc commands
4. Test with both human and LLM workflows
5. Release as v0.2.0 with migration guide