---
name: prepare-release
description: "Use when releasing, cutting release notes, or bumping the version everywhere"
---

# Prepare Release Skill

Copilot mirror of the canonical [`prepare-release`](../../../.agents/skills/prepare-release/SKILL.md)
skill. Keep both in sync when touchpoints or the release workflow change.

## Objective

Derive the version from the current branch name, write it to root `VERSION`
(SSOT), draft `docs/releases/vX.Y.Z.md` from the branch diff, and sync the
README release badge and `docs/Instructions.md` pointer.

## Rules

1. Never commit, tag, push, or run `gh release create` without an explicit ask.
2. Tagging (`git tag vX.Y.Z && git push origin vX.Y.Z`) is what publishes —
   `.github/workflows/release.yml` handles `gh release create` itself.
3. `VERSION` must match the pushed tag exactly, or the release workflow fails.

Full command sequence: see the canonical skill linked above.
