from __future__ import annotations

import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def badge_color(coverage: float) -> str:
    if coverage >= 95:
        return "#4c1"
    if coverage >= 90:
        return "#97ca00"
    if coverage >= 75:
        return "#dfb317"
    if coverage >= 50:
        return "#fe7d37"
    return "#e05d44"


def build_badge_svg(label_text: str, value_text: str, color: str) -> str:
    label_width = 61
    value_width = int(len(value_text) * 8.5) + 10
    total_width = label_width + value_width

    label_x = int((label_width / 2.0) * 10)
    value_x = int((label_width + (value_width / 2.0)) * 10)
    label_text_len = (label_width * 10) - 100
    value_text_len = (value_width * 10) - 100

    return "\n".join(
        [
            (
                f'<svg xmlns="http://www.w3.org/2000/svg" width="{total_width}" '
                f'height="20" role="img" aria-label="{label_text}: {value_text}">'
            ),
            f"    <title>{label_text}: {value_text}</title>",
            '    <linearGradient id="s" x2="0" y2="100%">',
            '        <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>',
            '        <stop offset="1" stop-opacity=".1"/>',
            "    </linearGradient>",
            '    <clipPath id="r">',
            f'        <rect width="{total_width}" height="20" rx="3" fill="#fff"/>',
            "    </clipPath>",
            '    <g clip-path="url(#r)">',
            f'        <rect width="{label_width}" height="20" fill="#555"/>',
            f'        <rect x="{label_width}" width="{value_width}" height="20" fill="{color}"/>',
            f'        <rect width="{total_width}" height="20" fill="url(#s)"/>',
            "    </g>",
            (
                '    <g fill="#fff" text-anchor="middle" '
                'font-family="Verdana,Geneva,DejaVu Sans,sans-serif" '
                'text-rendering="geometricPrecision" font-size="110">'
            ),
            (
                f'        <text aria-hidden="true" x="{label_x}" y="150" '
                'fill="#010101" fill-opacity=".3" transform="scale(.1)" '
                f'textLength="{label_text_len}">{label_text}</text>'
            ),
            (f'        <text x="{label_x}" y="140" transform="scale(.1)" fill="#fff" textLength="{label_text_len}">{label_text}</text>'),
            (
                f'        <text aria-hidden="true" x="{value_x}" y="150" '
                'fill="#010101" fill-opacity=".3" transform="scale(.1)" '
                f'textLength="{value_text_len}">{value_text}</text>'
            ),
            (f'        <text x="{value_x}" y="140" transform="scale(.1)" fill="#fff" textLength="{value_text_len}">{value_text}</text>'),
            "    </g>",
            "</svg>",
        ]
    )


def generate_badge(line_rate: str, output_path: Path = Path("badge.svg")) -> None:
    coverage = float(line_rate) * 100
    coverage_str = f"{int(coverage)}%"
    svg = build_badge_svg("Coverage", coverage_str, badge_color(coverage))
    output_path.write_text(svg, encoding="utf-8")
    print(f"Generated badge: {output_path} ({coverage_str})")


def ensure_root_attributes(root: ET.Element) -> None:
    default_attrs = {
        "branches-valid": "0",
        "branches-covered": "0",
        "lines-valid": "0",
        "lines-covered": "0",
        "version": "0",
        "timestamp": "0",
        "line-rate": "0.0",
        "branch-rate": "0.0",
    }
    for attr_name, attr_value in default_attrs.items():
        if attr_name not in root.attrib:
            root.set(attr_name, attr_value)


def flatten_packages(root: ET.Element) -> int:
    packages_el = root.find("packages")
    if packages_el is None:
        raise ValueError("No <packages> element found")

    all_classes: list[ET.Element] = []
    for package in packages_el.findall("package"):
        classes_el = package.find("classes")
        if classes_el is not None:
            all_classes.extend(classes_el.findall("class"))

    packages_el.clear()

    for cls in all_classes:
        filename = cls.get("filename", "unknown")
        new_pkg = ET.SubElement(packages_el, "package")
        new_pkg.set("name", filename)

        for attr in ["line-rate", "branch-rate", "complexity"]:
            new_pkg.set(attr, cls.get(attr, "0.0"))

        new_classes = ET.SubElement(new_pkg, "classes")
        new_classes.append(cls)

    return len(all_classes)


def transform_coverage(xml_file: Path) -> None:
    if not xml_file.exists():
        raise FileNotFoundError(f"{xml_file} not found")

    try:
        tree = ET.parse(xml_file)
    except ET.ParseError as exc:
        raise ValueError(f"Error parsing XML: {exc}") from exc

    root = tree.getroot()
    generate_badge(root.get("line-rate", "0"))

    class_count = flatten_packages(root)

    if root.find("sources") is None:
        sources = ET.SubElement(root, "sources")
        source = ET.SubElement(sources, "source")
        source.text = "."

    ensure_root_attributes(root)

    tree.write(xml_file, encoding="UTF-8", xml_declaration=True)
    print(f"Successfully transformed {xml_file}: split {class_count} classes into separate packages and fixed attributes.")


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("Usage: python transform_coverage.py <cobertura.xml>")
        return 1

    xml_path = Path(argv[1])
    try:
        transform_coverage(xml_path)
    except (FileNotFoundError, ValueError) as exc:
        print(exc)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
