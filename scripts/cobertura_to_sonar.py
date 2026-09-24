#!/usr/bin/env python3
"""Convert a kcov Cobertura report into SonarQube generic coverage XML.

kcov records absolute in-container paths (for example ``/app/bing_wallpaper.sh``).
SonarQube needs paths relative to the project root, so each file is mapped to the
shortest path suffix that exists under ``--root``. Files that cannot be mapped
(e.g. bats internals) are skipped.
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


def collect_lines(cobertura: ET.Element, root: Path) -> dict[str, dict[int, bool]]:
    sources = [s.text or "" for s in cobertura.iter("source")] or [""]
    coverage: dict[str, dict[int, bool]] = {}
    for cls in cobertura.iter("class"):
        filename = cls.get("filename", "")
        resolved = None
        for source in sources:
            resolved = resolve_repo_path(f"{source.rstrip('/')}/{filename}" if source else filename, root)
            if resolved:
                break
        if resolved is None:
            continue
        file_lines = coverage.setdefault(resolved, {})
        for line in cls.iter("line"):
            number = int(line.get("number", "0"))
            hits = int(line.get("hits", "0"))
            file_lines[number] = file_lines.get(number, False) or hits > 0
    return coverage


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
    parser.add_argument("--root", type=Path, default=Path.cwd(), help="Project root used to resolve file paths")
    args = parser.parse_args(argv)

    coverage = collect_lines(ET.parse(args.cobertura).getroot(), args.root.resolve())
    if not coverage:
        print(f"No project files found in {args.cobertura}", file=sys.stderr)
        return 1

    args.output.parent.mkdir(parents=True, exist_ok=True)
    build_generic_report(coverage).write(args.output, encoding="utf-8", xml_declaration=True)
    print(f"Wrote SonarQube coverage for {len(coverage)} file(s) to {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
