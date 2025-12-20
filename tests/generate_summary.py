import xml.etree.ElementTree as ET
import sys
import os

# Force UTF-8 output for emojis on Windows/CI
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

def generate_summary(xml_file):
    if not os.path.exists(xml_file):
        print(f"Error: {xml_file} not found")
        sys.exit(1)

    try:
        tree = ET.parse(xml_file)
        root = tree.getroot()
    except ET.ParseError as e:
        print(f"Error parsing XML: {e}")
        sys.exit(1)

    output = []
    output.append("## Detailed Code Coverage 📊")
    output.append("| File | Coverage | Lines | Missing |")
    output.append("| :--- | :---: | :---: | :--- |")

    # The transform_coverage script puts each file in its own package
    packages = root.findall('.//package')
    for pkg in packages:
        name = pkg.get('name')
        line_rate = float(pkg.get('line-rate', 0)) * 100
        
        # Count lines for this package
        cls = pkg.find('.//class')
        if cls is not None:
            lines = cls.findall('.//line')
            total = len(lines)
            missing_nums = []
            
            # Count covered and identify missing
            covered_count = 0
            for l in lines:
                if int(l.get('hits', 0)) > 0:
                    covered_count += 1
                else:
                    missing_nums.append(int(l.get('number')))
            
            # Format missing lines as ranges
            missing_str = ""
            if missing_nums:
                missing_nums.sort()
                ranges = []
                import itertools
                for k, g in itertools.groupby(enumerate(missing_nums), lambda x: x[0]-x[1]):
                    group = list(map(lambda x: x[1], g))
                    if len(group) > 1:
                        ranges.append(f"{group[0]}-{group[-1]}")
                    else:
                        ranges.append(str(group[0]))
                missing_str = ", ".join(ranges)
            
            output.append(f"| {name} | {line_rate:.1f}% | {covered_count}/{total} | {missing_str} |")

    # Print to stdout so it can be captured or redirected
    print("\n".join(output))

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python generate_summary.py <cobertura.xml>")
        sys.exit(1)
    
    generate_summary(sys.argv[1])
