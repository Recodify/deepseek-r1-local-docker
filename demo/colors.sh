#!/bin/bash

echo "Colors used in the ANSI art (with usage count):"
echo "---------------------------------------------"

grep -o '\[38;5;[0-9]\{3\}m' $1 | 
awk '
{
    count[$0]++
}
END {
    for (color in count) {
        num = substr(color, 6, 3)
        esc_color = "\033" substr(color, 2)  # Convert [38;5;XXXm to \e[38;5;XXXm
        printf("%s%5d uses - Color %s: ████████ \033[0m\n", 
               esc_color, count[color], num)
    }
}' | sort -rn