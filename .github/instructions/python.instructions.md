---
applyTo: "{tests,scripts}/**/*.py"
description: "Python coverage utility instructions with ruff+mypy enforcement"
---

# Python Instructions

Python guidance:

1. Keep files passing `ruff format --check`, `ruff check`, and `mypy`.
2. Add explicit type hints for public functions and key local structures.
3. Preserve XML and SVG output compatibility used by CI coverage reporting.
4. Prefer simple pure functions for report and badge transformations.
