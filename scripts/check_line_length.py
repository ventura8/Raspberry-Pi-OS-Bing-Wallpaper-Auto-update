#!/usr/bin/env python3
"""Check line length for repository source/config files."""

from __future__ import annotations

from pathlib import Path

MAX_LEN = 140

INCLUDE_EXTENSIONS = {
    ".sh",
    ".bash",
    ".py",
    ".ps1",
    ".yml",
    ".yaml",
    ".json",
    ".conf",
    ".toml",
    ".ini",
    ".cfg",
}

EXCLUDE_DIRS = {
    ".git",
    ".venv",
    ".mypy_cache",
    "__pycache__",
    "node_modules",
    "coverage",
    "coverage_inputs",
    "assets",
}


def should_check(path: Path) -> bool:
    if path.suffix.lower() == ".md":
        return False
    if path.name in {"Dockerfile"}:
        return True
    return path.suffix.lower() in INCLUDE_EXTENSIONS


def is_excluded(path: Path, root: Path) -> bool:
    rel = path.relative_to(root)
    return any(part in EXCLUDE_DIRS for part in rel.parts)


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    failures: list[str] = []

    for file_path in sorted(root.rglob("*")):
        if not file_path.is_file() or is_excluded(file_path, root):
            continue
        if not should_check(file_path):
            continue

        try:
            lines = file_path.read_text(encoding="utf-8").splitlines()
        except UnicodeDecodeError:
            continue

        for index, line in enumerate(lines, start=1):
            if len(line) > MAX_LEN:
                rel = file_path.relative_to(root).as_posix()
                failures.append(f"{rel}:{index}: line has {len(line)} chars (max {MAX_LEN})")

    if failures:
        print("Line length violations found:")
        for failure in failures:
            print(f"  - {failure}")
        return 1

    print(f"Line length check passed (max {MAX_LEN}).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
