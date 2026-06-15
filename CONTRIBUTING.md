# Contributing to Autotask AI Skills

Thank you for your interest in contributing! This guide will help you get started.

## How to Contribute

### Adding a New Skill

1. Create a new directory under `skills/` with the skill name (use `autotask-` prefix)
2. Create a `SKILL.md` file with YAML frontmatter:

```markdown
---
name: your-skill-name
description: One-line description of when to use this skill
---

# Skill Title

## Overview
What this skill covers.

## Sections
Detailed content with API examples.
```

3. Update the adapters in `adapters/` to include the new skill's knowledge
4. Submit a pull request

### Modifying Existing Skills

1. Edit the relevant `SKILL.md` file
2. Keep API examples as JSON code blocks
3. Document all field values and enums
4. Test with your AI tool before submitting

## Skill Guidelines

- **Frontmatter required**: Every SKILL.md must have `name` and `description` in YAML frontmatter
- **Use autotask-psa-api as base**: Reference it for authentication and query syntax
- **Be specific**: Include exact field names, values, and query examples
- **Keep it focused**: One domain per skill
- **Include examples**: Show real API requests and responses

## Updating Adapters

When you modify a skill, update the corresponding adapter files:

| Adapter | File | Format |
|---------|------|--------|
| Cursor | `adapters/cursor/.cursorrules` | Plain text rules |
| Windsurf | `adapters/windsurf/.windsurfrules` | Plain text rules |
| Continue | `adapters/continue/config.yaml` | YAML config |
| Aider | `adapters/aider/.aider.conf.yml` | YAML config |
| Copilot | `adapters/copilot/copilot-instructions.md` | Markdown |

## Reporting Issues

Open an issue with:
- Which skill is affected
- What API endpoint or feature is incorrect
- Expected vs actual behavior

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
