# Gemini CLI — Raspberry Pi OS Bing Wallpaper Auto-Update

Canonical agent rules for this repository: **[AGENTS.md](AGENTS.md)**.

This file is a thin project entrypoint for Gemini CLI context. Prefer `AGENTS.md`
over duplicating rules here.

Also load as needed:

- [docs/Instructions.md](docs/Instructions.md)
- [docs/project_overview.md](docs/project_overview.md)
- [docs/shell_scripts.md](docs/shell_scripts.md)
- [docs/development_standards.md](docs/development_standards.md)
- [`.agents/skills/`](.agents/skills/)

Optional import (if using Gemini `@` imports in your local setup):

```text
@./AGENTS.md
```

Quality/test gate order and the mocking policy live once in `AGENTS.md`. On
**every task**, update **all relevant Markdown files** in the same change set per
**Always Update Relevant Markdown** in `AGENTS.md`.
