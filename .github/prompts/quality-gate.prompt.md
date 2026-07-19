---
description: "Run or restore full repository quality-gate compliance"
---

# Quality Gate Prompt

Validate and restore repository quality compliance.

Steps:

1. Run `scripts/quality_checks.sh`.
2. Fix all reported issues without adding suppressions.
3. Re-run checks until clean.
4. Report modified files and the root cause of each fix category.
