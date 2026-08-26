---
name: coverage-badge
description: >-
  Merge kcov Cobertura output, enforce the 90% coverage threshold, and regenerate
  assets/coverage.svg + the Markdown coverage summary via tests/transform_coverage.py
  and tests/generate_summary.py. Use after test-affecting or coverage-tooling changes.
---

# Coverage Badge Skill

## Use when

- Test coverage may have changed (new/removed tests, new code paths)
- `tests/transform_coverage.py` or `tests/generate_summary.py` themselves change
- `assets/coverage.svg` looks stale relative to the last coverage-affecting change

## Hard rules

1. Total merged coverage must stay **≥90%** (`AGENTS.md`). Below that, add tests —
   do not lower the threshold.
2. CI validates coverage but does **not** commit the badge — regenerate
   `assets/coverage.svg` locally and commit it in the same change set as any
   coverage-affecting diff.
3. Keep the Cobertura XML shape (`line-rate` attribute, per-file/class rates)
   compatible with both `transform_coverage.py` and `generate_summary.py`.
4. Do not hand-edit `assets/coverage.svg` — always regenerate it from a real
   coverage run.

## Workflow (single-shot local coverage)

```bash
docker build -t wallpaper-test .
docker run --rm \
  --security-opt seccomp=unconfined --cap-add SYS_PTRACE \
  -v "$PWD:/app/workspace" -w /app/workspace \
  wallpaper-test bash tests/run_coverage.sh   # -> coverage/cobertura.xml

docker run --rm -v "$PWD:/workdir" -w /workdir \
  wallpaper-test python3 tests/transform_coverage.py coverage/cobertura.xml
# moves/refreshes badge.svg -> assets/coverage.svg
```

## Workflow (merged multi-suite coverage, matches CI `coverage-report` job)

Run each suite with `COVERAGE=1` into its own subdirectory (see
[test-runner](../test-runner/SKILL.md)), then:

```bash
docker run --rm \
  --security-opt seccomp=unconfined --cap-add SYS_PTRACE --user root \
  -v "$PWD:/workdir" -w /workdir \
  wallpaper-test kcov --merge coverage/merged \
    coverage_inputs/installer/* coverage_inputs/component/* coverage_inputs/system/*

merged_xml="$(find coverage/merged -name cobertura.xml | head -n 1)"
if [ ! -f "$merged_xml" ]; then
  echo "Merged cobertura.xml not found" >&2
  exit 1
fi
cp "$merged_xml" coverage/cobertura.xml

docker run --rm -v "$PWD:/workdir" -w /workdir wallpaper-test \
  python3 tests/transform_coverage.py coverage/cobertura.xml

docker run --rm -v "$PWD:/workdir" -w /workdir wallpaper-test \
  python3 tests/generate_summary.py coverage/cobertura.xml | tee coverage-summary.md
```

Enforce the threshold the same way CI does:

```python
import xml.etree.ElementTree as ET
root = ET.parse('coverage/cobertura.xml').getroot()
line_rate = float(root.get('line-rate', '0')) * 100
if line_rate < 90.0:
    raise SystemExit(f'Coverage below 90% threshold: {line_rate:.2f}%')
```

## Windows shortcut

```powershell
./scripts/local/run_coverage_local.ps1   # single-shot coverage run + badge
./scripts/local/run_tests_local.ps1      # full merged pipeline; fails if coverage < 90%
```
