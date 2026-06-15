# Autotask AI Skills

## Project Overview
This is a collection of AI skills for Autotask PSA integration. Skills are defined as SKILL.md files in the `skills/` directory using Claude Code's native skill format.

## Structure
- `skills/` - All skill definitions (one subdirectory per skill)
- `adapters/` - Converted formats for other AI tools (Cursor, Windsurf, etc.)
- `install.sh` / `install.ps1` - Installation scripts
- `examples/` - Usage examples

## Guidelines
- Each skill is a standalone SKILL.md with YAML frontmatter (`name`, `description`)
- Skills reference each other by name (e.g., "Use `autotask-psa-api` for auth")
- The `autotask-psa-api` skill is the foundation - all others depend on it
- Keep API examples as JSON code blocks
- Document all entity field values and enums
