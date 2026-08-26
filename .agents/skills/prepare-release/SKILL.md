---
name: prepare-release
description: >-
  Prepare a versioned release from the current branch: set VERSION, write
  docs/releases notes, sync the README badge and docs pointers. Use when
  releasing, cutting release notes, or bumping the version across the repo.
---

# Prepare Release Skill

Use when the user asks to prepare a release, cut release notes, bump the
version everywhere, or finalize the current versioned branch for
tagging/GitHub Release.

## Goals

1. Derive the release version from the **current git branch name**.
2. Set root [`VERSION`](../../../VERSION) to that version (repo **SSOT**).
3. Sync the README release badge and docs that cite the current release.
4. Create/update `docs/releases/vX.Y.Z.md` (GitHub Release body source).
5. Do **not** commit, amend, tag, push, or `gh release create` unless the user
   explicitly asks in the same turn.

## Version from branch

Parse `git branch --show-current`:

| Branch example | Version |
| --- | --- |
| `feature/v1.0.2` | `v1.0.2` |
| `release/v1.0.2` | `v1.0.2` |
| `v1.0.2` | `v1.0.2` |
| `feature/1.0.2` | `v1.0.2` |

Rules:

1. Extract the first semver-like token `MAJOR.MINOR.PATCH` (optional leading `v`).
2. Normalize to **`vMAJOR.MINOR.PATCH`** for `VERSION`, tags, badges, and docs.
3. If no version can be parsed, **stop** and ask the user.

## Version touchpoints (keep in sync)

| Path | Form |
| --- | --- |
| `VERSION` | `vX.Y.Z` + newline |
| `README.md` release badge | `release-vX.Y.Z` → `docs/releases/vX.Y.Z.md` |
| `docs/Instructions.md` | Release notes index entry (latest, with prior link) |
| `docs/releases/vX.Y.Z.md` | Full release notes |

Leave historical `docs/releases/vPREV.md` unchanged. This repo does not embed a
version string inside `bing_wallpaper.sh` / `install.sh` / `uninstall.sh` — do
not invent one; if that changes, add it to this table in the same change set.

## Workflow

### 1) Inspect

```bash
git branch --show-current
git status -sb
git log --oneline main..HEAD
git diff --stat main...HEAD
```

### 2) Draft notes from the full branch delta

Cover product (`bing_wallpaper.sh`/`install.sh`/`uninstall.sh`), CI/quality
gates, tests/coverage, and docs/agent-doc changes that actually land in the
release. Mirror the tone and structure of the latest prior file under
`docs/releases/` (see `docs/releases/v1.0.1.md`).

### 3) Write version + docs

1. Write `VERSION`.
2. Write `docs/releases/vX.Y.Z.md`.
3. Update the README release badge and `docs/Instructions.md` release pointer.

### 4) Hygiene checklist

- Coverage floor still stated as **90%** where mentioned ([AGENTS.md](../../../AGENTS.md)).
- Badge rule: local update of `assets/coverage.svg`; CI does not refresh it —
  regenerate it first if coverage-affecting changes landed (see
  [coverage-badge](../coverage-badge/SKILL.md)).
- `AGENTS.md` skill index lists skills that actually exist.
- No contradictory install/quality commands across README and runners.

### 5) Verify (no commit unless asked)

```bash
test "$(tr -d '[:space:]' < VERSION)" = "vX.Y.Z"
test -f "docs/releases/vX.Y.Z.md"
grep -n "vX.Y.Z" README.md docs/Instructions.md
```

## Hard rules

1. Version comes from the **branch name**, written to root **`VERSION`**.
2. GitHub description path is always `docs/releases/vX.Y.Z.md`.
3. Do not invent features absent from the branch diff.
4. Do not amend/commit/tag/push/`gh release create` without an explicit ask.
5. Prefer running [pipeline-runner](../pipeline-runner/SKILL.md) before tagging
   if tests were not just validated.

## Tagging triggers the GitHub Release (automated, do not hand-run `gh release create`)

Once `VERSION` and `docs/releases/vX.Y.Z.md` are committed on the branch that
will become `main`, the only remaining step to publish is creating and pushing
the tag:

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

[`.github/workflows/release.yml`](../../../.github/workflows/release.yml) fires
on that `v*` tag push, verifies `VERSION` matches the tag and
`docs/releases/vX.Y.Z.md` exists, then runs `gh release create` itself with the
notes file's H1 as the title and the rest as the body. Only tag/push when the
user explicitly asks — this publishes a public release.

## Output to the user

1. Parsed version + branch + `VERSION` contents
2. Paths updated
3. Whether commit / tag+push is still pending (tagging publishes automatically
   via `release.yml` — no manual `gh release create`)
