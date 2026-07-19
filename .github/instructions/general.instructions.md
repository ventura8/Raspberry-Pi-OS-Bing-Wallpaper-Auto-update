---
applyTo: "**"
description: "Repository-wide instructions for Bash wallpaper project quality and CI parity"
---

# General Instructions

Follow these repository-wide rules:

1. Run `scripts/quality_checks.sh` before proposing final changes.
2. Keep local and CI quality gates identical.
3. Do not introduce lint suppressions or disable comments.
4. Keep non-Markdown source/config lines at 140 chars or fewer.
5. Preserve existing behavior unless the task explicitly requests behavior changes.
