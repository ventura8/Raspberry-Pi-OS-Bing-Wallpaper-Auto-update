from __future__ import annotations

import ast
import itertools
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

TARGET_COMPLEXITY = 10.0
MAX_FILE_COMPLEXITY = 20.0
MAX_AVG_COMPLEXITY = 10.0


def parse_float(value: str | None) -> float:
    try:
        return float(value) if value is not None else 0.0
    except ValueError:
        return 0.0


def resolve_source_file(xml_file: Path, declared_name: str) -> Path | None:
    declared = Path(declared_name)
    if declared.is_absolute():
        declared = Path(declared.name)

    root = xml_file.resolve().parents[1]

    direct_candidate = root / declared.as_posix()
    if direct_candidate.exists():
        return direct_candidate

    name_only = declared.name
    for candidate in (root / "").rglob(name_only):
        if candidate.is_file() and ".git" not in candidate.parts:
            return candidate

    return None


def python_complexity(path: Path) -> float:
    try:
        source = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return 0.0

    try:
        module = ast.parse(source)
    except SyntaxError:
        return 0.0

    def node_complexity(node: ast.AST) -> float:
        complexity = 1.0
        for sub_node in ast.walk(node):
            if isinstance(sub_node, (ast.If, ast.For, ast.While, ast.Try, ast.With, ast.Match, ast.IfExp, ast.ExceptHandler)):
                complexity += 1.0
            elif isinstance(sub_node, ast.BoolOp):
                complexity += max(0, len(sub_node.values) - 1)
            elif isinstance(sub_node, (ast.ListComp, ast.SetComp, ast.DictComp, ast.GeneratorExp)):
                complexity += max(1, len(sub_node.generators))
        return complexity

    function_complexities: list[float] = []
    for node in module.body:
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            function_complexities.append(node_complexity(node))

    if function_complexities:
        return max(function_complexities)

    return node_complexity(module)


def shell_block_complexity(block_source: str) -> float:
    complexity = 1

    keyword_patterns = [
        r"\bif\b",
        r"\belif\b",
        r"\bfor\b",
        r"\bwhile\b",
        r"\buntil\b",
        r"\bcase\b",
    ]

    for pattern in keyword_patterns:
        complexity += len(re.findall(pattern, block_source))

    complexity += block_source.count("&&")
    complexity += block_source.count("||")

    return float(complexity)


def extract_shell_function_bodies(source: str) -> list[str]:
    function_start_pattern = re.compile(r"(?m)^\s*[a-zA-Z_][a-zA-Z0-9_]*\s*\(\)\s*\{")
    bodies: list[str] = []

    for match in function_start_pattern.finditer(source):
        start = match.end()
        depth = 1
        index = start
        while index < len(source):
            char = source[index]
            if char == "{":
                depth += 1
            elif char == "}":
                depth -= 1
                if depth == 0:
                    bodies.append(source[start:index])
                    break
            index += 1

    return bodies


def shell_complexity(path: Path) -> float:
    try:
        source = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return 0.0

    function_bodies = extract_shell_function_bodies(source)
    if function_bodies:
        return max(shell_block_complexity(body) for body in function_bodies)

    return shell_block_complexity(source)


def complexity_rating(value: float) -> str:
    if value <= TARGET_COMPLEXITY:
        return "good"
    if value <= MAX_FILE_COMPLEXITY:
        return "warning"
    return "fail"


def measured_complexity(xml_file: Path, declared_name: str, fallback: float) -> float:
    source_path = resolve_source_file(xml_file, declared_name)
    if source_path is None:
        return fallback

    suffix = source_path.suffix.lower()
    if suffix == ".py":
        value = python_complexity(source_path)
        return value if value > 0 else fallback
    if suffix in {".sh", ".bash"}:
        value = shell_complexity(source_path)
        return value if value > 0 else fallback

    return fallback


def format_ranges(numbers: list[int]) -> str:
    if not numbers:
        return ""

    numbers.sort()
    ranges: list[str] = []

    for _, group in itertools.groupby(enumerate(numbers), lambda x: x[0] - x[1]):
        grouped_numbers = [item[1] for item in group]
        if len(grouped_numbers) > 1:
            ranges.append(f"{grouped_numbers[0]}-{grouped_numbers[-1]}")
        else:
            ranges.append(str(grouped_numbers[0]))

    return ", ".join(ranges)


def generate_summary(xml_file: Path) -> None:
    if not xml_file.exists():
        print(f"Error: {xml_file} not found")
        raise SystemExit(1)

    try:
        tree = ET.parse(xml_file)
        root = tree.getroot()
    except ET.ParseError as exc:
        print(f"Error parsing XML: {exc}")
        raise SystemExit(1) from exc

    file_rows: list[tuple[str, float, int, int, float, str, str]] = []

    total_lines = 0
    covered_lines = 0
    total_complexity = 0.0
    file_count = 0
    complexity_violations: list[str] = []

    for package in root.findall(".//package"):
        name = package.get("name", "unknown")
        line_rate = float(package.get("line-rate", "0")) * 100

        # Contract: transform_coverage.py flattens cobertura to one class per package.
        classes = package.findall("./classes/class")
        if not classes:
            continue
        if len(classes) > 1:
            print(f"Error: expected exactly one <class> per <package> after flattening, but found {len(classes)} for package '{name}'.")
            raise SystemExit(1)

        cls = classes[0]

        lines = cls.findall(".//line")
        total = len(lines)
        covered_count = 0
        missing_nums: list[int] = []

        for line in lines:
            hits = int(line.get("hits", "0"))
            if hits > 0:
                covered_count += 1
            else:
                missing_nums.append(int(line.get("number", "0")))

        complexity_attr = parse_float(cls.get("complexity") or package.get("complexity"))
        declared_name = cls.get("filename", name)
        complexity = measured_complexity(xml_file, declared_name, complexity_attr)
        complexity_status = complexity_rating(complexity)
        line_rate = (covered_count / total * 100) if total else 0.0
        missing = format_ranges(missing_nums)
        file_rows.append((name, line_rate, covered_count, total, complexity, complexity_status, missing))

        if complexity_status == "fail":
            complexity_violations.append(f"{name}: {complexity:.2f} (max {MAX_FILE_COMPLEXITY:.2f})")

        file_count += 1
        total_lines += total
        covered_lines += covered_count
        total_complexity += complexity

    overall_coverage = (covered_lines / total_lines * 100) if total_lines else 0.0
    average_complexity = (total_complexity / file_count) if file_count else 0.0

    output = [
        "## Complexity Snapshot",
        "| File | Complexity | Status |",
        "| :--- | :---: | :---: |",
    ]

    status_labels = {"good": "OK", "warning": "WARN", "fail": "FAIL"}
    for name, _, _, _, complexity, complexity_status, _ in file_rows:
        output.append(f"| {name} | {complexity:.2f} | {status_labels[complexity_status]} |")

    output.extend(
        [
            "",
            "## Detailed Code Coverage",
            "| File | Coverage | Lines | Complexity | Missing |",
            "| :--- | :---: | :---: | :---: | :--- |",
        ]
    )

    for name, line_rate, covered_count, total, complexity, _, missing in file_rows:
        output.append(f"| {name} | {line_rate:.1f}% | {covered_count}/{total} | {complexity:.2f} | {missing} |")

    output.extend(
        [
            "",
            "## Overall Coverage and Complexity",
            "| Metric | Value |",
            "| :--- | :---: |",
            f"| Files | {file_count} |",
            f"| Coverage | {overall_coverage:.2f}% ({covered_lines}/{total_lines}) |",
            f"| Complexity (total) | {total_complexity:.2f} |",
            f"| Complexity (avg/file) | {average_complexity:.2f} |",
            "",
            "## Complexity Policy",
            "| Threshold | Value |",
            "| :--- | :---: |",
            f"| Target complexity per file | <= {TARGET_COMPLEXITY:.2f} |",
            f"| Maximum complexity per file | <= {MAX_FILE_COMPLEXITY:.2f} |",
            f"| Maximum average complexity | <= {MAX_AVG_COMPLEXITY:.2f} |",
        ]
    )

    if average_complexity > MAX_AVG_COMPLEXITY:
        complexity_violations.append(f"Average complexity: {average_complexity:.2f} (max {MAX_AVG_COMPLEXITY:.2f})")

    if complexity_violations:
        output.extend(["", "## Complexity Violations"])
        output.extend(f"- {violation}" for violation in complexity_violations)

    print("\n".join(output))

    if complexity_violations:
        raise SystemExit(1)


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("Usage: python generate_summary.py <cobertura.xml>")
        return 1

    generate_summary(Path(argv[1]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
