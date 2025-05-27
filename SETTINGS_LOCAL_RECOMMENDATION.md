# settings.local.json Recommendation for pc

## Overview
Recommendation to add frequently used pc commands to Claude Code's settings.local.json for streamlined permissions.

## Current Observations

The example settings.local.json at ~/tools/.claude/settings.local.json shows project-specific tool permissions:
- Multiple entries for commonly used commands (chezmoi, hx, cargo, etc.)
- Project-specific scripts get explicit permissions
- Reduces permission prompts during development

## Recommended Additions for pc Users

```json
{
  "permissions": {
    "allow": [
      "Bash(pc:*)",
      "Bash(pc status:*)",
      "Bash(pc switch:*)",
      "Bash(pc todo:*)",
      "Bash(pc log:*)",
      "Bash(pc stash:*)",
      "Bash(pc pop:*)",
      "Bash(pc sync:*)",
      "Bash(./pc_unified.sh:*)",
      "Bash(~/.local/bin/pc:*)"
    ]
  }
}
```

## Benefits

1. **Seamless Workflow**: No permission prompts when using pc commands
2. **Development Testing**: Easy testing of pc scripts during development
3. **Command Variations**: Covers installed version and development versions

## Implementation Guide

Users can add these to their project's .claude/settings.local.json:

1. Create `.claude/` directory in project root
2. Add `settings.local.json` with pc permissions
3. Include any project-specific tools they use frequently

## Documentation Update

Should add a section to USER_GUIDE.md explaining:
- How to set up settings.local.json for pc
- Benefits of pre-approving permissions
- Example configuration for common workflows