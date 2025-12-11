# Contributing to Guard Wolves

Thank you for your interest in contributing to Guard Wolves! This document provides guidelines for contributing to the project.

## How to Contribute

### Reporting Bugs

Before creating a bug report, please check existing issues to avoid duplicates.

**When reporting a bug, include:**
- Minecraft version
- Denizen version
- Citizens version (if applicable)
- Server software (Spigot/Paper/etc.) and version
- Steps to reproduce the bug
- Expected behavior
- Actual behavior
- Relevant logs (with `/gw tl` debug enabled if possible)
- Screenshots or videos if applicable

### Suggesting Features

We welcome feature suggestions! Please:
- Check existing issues for similar suggestions
- Clearly describe the feature and its use case
- Explain how it benefits users
- Consider implementation complexity

### Pull Requests

1. **Fork the repository** and create a new branch for your feature/fix
2. **Make your changes** following the code style guidelines below
3. **Test thoroughly** on a Minecraft server with Denizen installed
4. **Update documentation** if your changes affect usage
5. **Update CHANGELOG.md** with your changes under `[Unreleased]`
6. **Submit a pull request** with a clear description of changes

## Code Style Guidelines

### Denizen Script Style

- **Indentation:** 2 spaces (no tabs)
- **Comments:** Use comments to explain complex logic
- **Line length:** Aim for 120 characters max
- **Naming:**
  - Commands: `snake_case` (e.g., `guard_wolves_command`)
  - Variables: `snake_case` with descriptive names (e.g., `[wolf_display_name]`)
  - Flags: `snake_case` (e.g., `guard_mode`, `original_owner`)

### Script Organization

- Keep related functionality together
- Use clear section comments (e.g., `# COMBAT:`, `# HEALTH MANAGEMENT:`)
- Separate different script types (command, world events, tasks)

### Example:

```yaml
guard_wolves_command:
  type: command
  name: guard_wolves
  description: Manage your guard wolves
  usage: /guard_wolves <&lt>list|toggle_logs<&gt>
  aliases:
  - gw
  script:
  # Get subcommand
  - define subcommand <context.args.get[1]||null>

  # LIST subcommand
  - if <[subcommand]> == list || <[subcommand]> == ls:
    - narrate "<gold>Your wolves:"
    # ... implementation
```

## Testing

Before submitting changes:

1. **Test on a live server** with Denizen installed
2. **Test all commands** (`/gw ls`, `/gw tl`)
3. **Test guard mode** toggle (enable/disable)
4. **Test combat behavior** with hostile mobs
5. **Test edge cases:**
   - Server restart with active guard wolves
   - Teleporting guard wolves
   - Wolf death notifications
   - Multiple players with guard wolves
   - Wolves in different worlds

## Documentation

If your changes affect user-facing behavior:

1. **Update README.md** with new features/changes
2. **Update command reference** if commands change
3. **Add configuration examples** for new customizable options
4. **Update troubleshooting section** if adding common issues

## Questions?

- Open a discussion in the Issues tab
- Reach out via GitHub

## Code of Conduct

- Be respectful and constructive
- Welcome newcomers
- Focus on the best outcome for the project
- Accept constructive criticism gracefully

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for helping make Guard Wolves better!
