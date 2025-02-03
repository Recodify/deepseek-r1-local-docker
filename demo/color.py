import re
import os
import sys
from collections import Counter

def ansi_to_rgb(ansi_code):
    """Converts ANSI 256 color codes to their corresponding RGB values."""
    if ansi_code < 16:  # Standard colors
        standard_colors = [
            (0, 0, 0), (128, 0, 0), (0, 128, 0), (128, 128, 0),
            (0, 0, 128), (128, 0, 128), (0, 128, 128), (192, 192, 192),
            (128, 128, 128), (255, 0, 0), (0, 255, 0), (255, 255, 0),
            (0, 0, 255), (255, 0, 255), (0, 255, 255), (255, 255, 255)
        ]
        return standard_colors[ansi_code]
    elif 16 <= ansi_code <= 231:  # 6x6x6 color cube
        ansi_code -= 16
        r = (ansi_code // 36) * 51
        g = ((ansi_code % 36) // 6) * 51
        b = (ansi_code % 6) * 51
        return (r, g, b)
    else:  # Grayscale
        gray = 8 + (ansi_code - 232) * 10
        return (gray, gray, gray)

def parse_ansi_file(filename):
    """Parses an ANSI file and extracts color usage."""
    with open(filename, 'rb') as f:
        data = f.read().decode(errors='ignore')
    
    ansi_codes = re.findall(r'\x1b\[38;5;(\d+)m', data)
    color_counts = Counter(map(int, ansi_codes))
    return color_counts

def generate_html_report(color_counts, output_file):
    """Generates an HTML report displaying the ANSI colors."""
    html_content = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>ANSI Colors Report</title>
        <style>
            body { font-family: Arial, sans-serif; }
            .color-box { display: flex; align-items: center; padding: 5px; margin: 5px; border: 1px solid #ccc; }
            .color-sample { width: 50px; height: 20px; margin-right: 10px; border: 1px solid #000; }
        </style>
    </head>
    <body>
        <h2>ANSI Colors Report</h2>
        <div>
    """
    
    for ansi_code, count in color_counts.items():
        rgb = ansi_to_rgb(ansi_code)
        hex_color = f'#{rgb[0]:02X}{rgb[1]:02X}{rgb[2]:02X}'
        html_content += f'''
            <div class="color-box">
                <div class="color-sample" style="background-color: {hex_color};"></div>
                <span>ANSI {ansi_code} - {rgb} - {hex_color} - {count} chars</span>
            </div>
        '''
    
    html_content += """
        </div>
    </body>
    </html>
    """
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html_content)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python color.py <input_ansi_file>")
        sys.exit(1)
    input_file = sys.argv[1]
    output_file = "ansi_colors_report.html"
    
    color_counts = parse_ansi_file(input_file)
    generate_html_report(color_counts, output_file)
    print(f"HTML report generated: {output_file}")
