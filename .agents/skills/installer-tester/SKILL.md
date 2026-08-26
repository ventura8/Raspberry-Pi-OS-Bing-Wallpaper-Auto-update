---
name: installer-tester
description: >-
  Validate install.sh and uninstall.sh interactive prompts, crontab scheduling,
  and first-run wallpaper apply using bats and the mocked crontab/curl binaries.
  Use when changing install/uninstall flows or cron behavior.
---

# Installer Tester Skill

## Use when

- Editing `install.sh` or `uninstall.sh`
- Changing cron scheduling, interactive prompts, or the region/resolution defaults
- Debugging `install_test.bats` / `uninstall_test.bats` failures

## Hard rules

1. `install.sh` and `uninstall.sh` are driven entirely by interactive stdin in
   tests (`run bash install.sh <<< "..."`) — there is no `NON_INTERACTIVE` /
   env-preset install path. Preserve that contract; do not silently add one
   without updating this skill and the bats fixtures together.
2. Fail closed on network failure (`tests/mocks/curl` returning empty/failed) and
   on missing/invalid region or cron input — reprompt, don't crash.
3. Cover both default answers (blank input → `en-WW`, 10:00 cron) and explicit
   overrides (custom region, custom `HH:MM`, invalid-then-valid input) in tests.
4. Keep cron writes idempotent: re-running the installer must update the existing
   `bing_wallpaper.sh` crontab line, not duplicate it.
5. When install/uninstall behavior changes, sync `AGENTS.md`, this skill, and
   `.github/skills/project-quality` / `coverage-workflow` references in the same
   change set if commands or paths moved.

## Behavior to preserve

- `install.sh`: prompt for Bing region (default `en-WW`), resolution, and cron
  `HH:MM` (default `10:00`); write/replace the crontab line
  `MIN HOUR * * * $INSTALL_DIR/bing_wallpaper.sh >/dev/null 2>&1`; run the
  wallpaper script once after install.
- `uninstall.sh`: remove `$INSTALL_DIR/bing_wallpaper.sh`, its log file, and the
  matching crontab entry.
- `tests/mocks/crontab` records writes to `crontab.mock` under the mocked `$HOME`
  so tests can assert on the resulting cron line.

## Workflow

```bash
docker build -t wallpaper-test .

docker run --rm \
  --security-opt seccomp=unconfined \
  --cap-add SYS_PTRACE \
  -e COVERAGE=1 \
  -e COVERAGE_OUTPUT=/app/coverage \
  -v "$PWD/coverage:/app/coverage" \
  wallpaper-test ./tests/run_suite.sh --file tests/install_test.bats

docker run --rm \
  --security-opt seccomp=unconfined \
  --cap-add SYS_PTRACE \
  -e COVERAGE=1 \
  -e COVERAGE_OUTPUT=/app/coverage \
  -v "$PWD/coverage:/app/coverage" \
  wallpaper-test ./tests/run_suite.sh --file tests/uninstall_test.bats
```

Also run `--e2e-only` (`tests/e2e_tests.bats`) when the install→run→uninstall
composition may have changed.
