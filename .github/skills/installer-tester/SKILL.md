---
name: installer-tester
description: "Use when changing install.sh / uninstall.sh, cron wiring, or their bats tests"
---

# Installer Tester Skill

Copilot mirror of the canonical [`installer-tester`](../../../.agents/skills/installer-tester/SKILL.md)
skill. Keep both in sync when commands or invariants change.

## Objective

Keep `install.sh` and `uninstall.sh` interactive prompts, cron wiring, and
first-run behavior correct and covered by `tests/install_test.bats` /
`tests/uninstall_test.bats`.

## Rules

1. Drive both scripts via stdin in tests — no `NON_INTERACTIVE` env path exists.
2. Fail closed on network failure or invalid region/cron input; reprompt.
3. Cron writes must be idempotent (update, not duplicate, the crontab line).
4. Never mock `install.sh` / `uninstall.sh` themselves in tests.

## Entry point

```bash
docker build -t wallpaper-test .

docker run --rm --pull=never -v "$PWD:/workdir" -w /workdir \
  wallpaper-test ./tests/run_suite.sh --installer-only
```

Omit `COVERAGE=1` and kcov privileges (`--security-opt seccomp=unconfined`,
`--cap-add SYS_PTRACE`) unless you are collecting coverage — kcov requires them.
