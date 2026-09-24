#!/usr/bin/env python3
"""Convert a kcov Cobertura report into SonarQube generic coverage XML.

kcov records absolute in-container paths (for example ``/app/bing_wallpaper.sh``).
SonarQube needs paths relative to the project root, so each file is mapped to the
shortest path suffix that exists under the project root (the current working
directory). Files that cannot be mapped (e.g. bats internals) are skipped. Input and
output paths must stay inside the project root.
"""

from __future__ import annotations

import argparse
import sys
import xml.etree.ElementTree as ET
from pathlib import Path, PurePosixPath


def resolve_repo_path(raw_path: str, root: Path) -> str | None:
    parts = PurePosixPath(raw_path.replace("\\", "/")).parts
    for start in range(len(parts)):
        candidate = PurePosixPath(*parts[start:])
        if str(candidate) in ("", "/"):
            continue
        if (root / candidate).is_file():
            return candidate.as_posix()
    return None


def resolve_class_path(filename: str, sources: list[str], root: Path) -> str | None:
    for source in sources:
        raw_path = f"{source.rstrip('/')}/{filename}" if source else filename
        resolved = resolve_repo_path(raw_path, root)
        if resolved:
            return resolved
    return None


def merge_class_lines(cls: ET.Element, file_lines: dict[int, bool]) -> None:
    for line in cls.iter("line"):
        number = int(line.get("number", "0"))
        covered = int(line.get("hits", "0")) > 0
        file_lines[number] = file_lines.get(number, False) or covered


def collect_lines(cobertura: ET.Element, root: Path) -> dict[str, dict[int, bool]]:
    sources = [s.text or "" for s in cobertura.iter("source")] or [""]
    coverage: dict[str, dict[int, bool]] = {}
    for cls in cobertura.iter("class"):
        resolved = resolve_class_path(cls.get("filename", ""), sources, root)
        if resolved is not None:
            merge_class_lines(cls, coverage.setdefault(resolved, {}))
    return coverage


def confine_to_root(path: Path, root: Path) -> Path:
    """Resolve ``path`` and refuse anything outside the project root."""
    resolved = (root / path).resolve()
    if not resolved.is_relative_to(root):
        raise ValueError(f"Path {path} is outside the project root {root}")
    return resolved


def build_generic_report(coverage: dict[str, dict[int, bool]]) -> ET.ElementTree:
    report = ET.Element("coverage", version="1")
    for path in sorted(coverage):
        file_el = ET.SubElement(report, "file", path=path)
        for number, covered in sorted(coverage[path].items()):
            ET.SubElement(file_el, "lineToCover", lineNumber=str(number), covered=str(covered).lower())
    return ET.ElementTree(report)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("cobertura", type=Path, help="Input Cobertura XML (kcov output)")
    parser.add_argument("output", type=Path, help="Output SonarQube generic coverage XML")
    args = parser.parse_args(argv)

    root = Path.cwd().resolve()
    try:
        cobertura_path = confine_to_root(args.cobertura, root)
        output_path = confine_to_root(args.output, root)
    except ValueError as error:
        print(error, file=sys.stderr)
        return 2

    coverage = collect_lines(ET.parse(cobertura_path).getroot(), root)
    if not coverage:
        print(f"No project files found in {cobertura_path}", file=sys.stderr)
        return 1

    output_path.parent.mkdir(parents=True, exist_ok=True)
    build_generic_report(coverage).write(output_path, encoding="utf-8", xml_declaration=True)
    print(f"Wrote SonarQube coverage for {len(coverage)} file(s) to {output_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
