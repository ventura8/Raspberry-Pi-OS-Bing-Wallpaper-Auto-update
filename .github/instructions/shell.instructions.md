---
applyTo: "**/*.sh"
description: "Shell scripting instructions for wallpaper runtime and test shell utilities"
---

# Shell Instructions

Shell guidance:

1. Keep scripts `shellcheck -S style` clean.
2. Keep scripts `shfmt -i 2 -ci` clean.
3. Prefer Bash parameter expansion over external text tools where practical.
4. Quote variables unless intentionally relying on word splitting.
5. Keep changes portable for Raspberry Pi OS and Xubuntu environments.
