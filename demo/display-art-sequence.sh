#!/bin/bash

# Helper function to clear previous lines
clear_lines() {
    local num_lines=$1
    for ((i=0; i<num_lines; i++)); do
        echo -en "\033[2K" # Clear entire line
        echo -en "\033[1A" # Move up one line
    done
    echo -en "\033[2K" # Clear the last line
}

# Add color code mapping function
get_color_code() {
    local color="${1:-blue}"
    local variant="${2:-base}"

    # Base colors (30-37)
    local -A base_colors=(
        ["black"]="30" ["red"]="31" ["green"]="32" ["yellow"]="33"
        ["blue"]="34" ["magenta"]="35" ["cyan"]="36" ["white"]="37"
    )

    # Bright colors (90-97)
    local -A bright_colors=(
        ["black"]="90" ["red"]="91" ["green"]="92" ["yellow"]="93"
        ["blue"]="94" ["magenta"]="95" ["cyan"]="96" ["white"]="97"
    )

    local color_code
    case "$variant" in
        "base")
            color_code="${base_colors[$color]:-34}"  # Default to blue
            ;;
        "bright")
            color_code="${bright_colors[$color]:-94}"  # Default to bright blue
            ;;
        "bold")
            color_code="1;${base_colors[$color]:-34}"  # Bold version of base color
            ;;
        *)
            color_code="${base_colors[$color]:-34}"  # Default to base blue
            ;;
    esac

    echo "$color_code"
}

# Animation effects functions
fade_in() {
    local color_code="$1"
    shift
    local -a art_lines=("$@")
    local total_lines=${#art_lines[@]}

    # Extract base color number for fading
    local base_color="${color_code##*;}"  # Remove everything before last semicolon
    local prefix=""
    [[ "$color_code" == *";"* ]] && prefix="${color_code%;*};"  # Keep bold prefix if it exists

    # First show in dark gray
    for ((i=0; i<total_lines; i++)); do
        colored_line=$(echo "${art_lines[$i]}" | sed 's/[(/|_\\,]/\x1b[90m&\x1b[0m/g')
        echo -e "$colored_line"
    done

    # Fade through shades to final color
    for shade in 90 $(( base_color - 1 )) $base_color; do
        clear_lines "$total_lines"
        for ((i=0; i<total_lines; i++)); do
            colored_line=$(echo "${art_lines[$i]}" | sed "s/[(/|_\\,]/\x1b[${prefix}${shade}m&\x1b[0m/g")
            echo -e "$colored_line"
        done
        sleep 0.3
    done

    # Final display
    clear_lines "$total_lines"
    display_final "$color_code" "${art_lines[@]}"
}

bounce_in() {
    local color_code="$1"
    shift
    local -a art_lines=("$@")
    local total_lines=${#art_lines[@]}
    local padding=5
    local total_height=$((total_lines + padding))

    # Start with extra newlines
    for ((i=0; i<total_height; i++)); do
        echo
    done

    # Bounce effect
    for ((bounce=padding; bounce>=0; bounce--)); do
        clear_lines "$total_height"

        # Print padding
        for ((i=0; i<bounce; i++)); do
            echo
        done

        # Print art
        display_final "$color_code" "${art_lines[@]}"

        # Fill remaining space
        for ((i=0; i<(padding-bounce); i++)); do
            echo
        done

        sleep $((bounce == 0 ? 0 : 1))
    done
}

pop() {
    local color_code="$1"
    shift
    local -a art_lines=("$@")
    local total_lines=${#art_lines[@]}

    # Start from the bottom, showing one line at a time
    for ((i=0; i<total_lines; i++)); do
        # Print the new line
        colored_line=$(echo "${art_lines[$i]}" | sed "s/[(/|_\\,]/\x1b[${color_code}m&\x1b[0m/g")
        echo -e "$colored_line"
        sleep 0.2
    done
}

pop_overlay() {
    local color_code="$1"
    shift
    local -a art_lines=("$@")
    local total_lines=${#art_lines[@]}

    # Save cursor position
    echo -en "\033[s"

    # Print empty lines first to reserve space
    for ((i=0; i<total_lines; i++)); do
        echo
    done

    # Move back up
    echo -en "\033[${total_lines}A"

    # Show lines one by one
    for ((i=0; i<total_lines; i++)); do
        colored_line=$(echo "${art_lines[$i]}" | sed "s/[(/|_\\,]/\x1b[${color_code}m&\x1b[0m/g")
        echo -en "\r\033[K${colored_line}\n"
        sleep 0.2
    done
}

display_final() {
    local color_code="$1"
    shift
    local -a art_lines=("$@")
    for line in "${art_lines[@]}"; do
        colored_line=$(echo "$line" | sed "s/[(/|_\\,]/\x1b[${color_code}m&\x1b[0m/g")
        echo -e "$colored_line"
    done
}

# Animation effects functions
rainbow() {
    local final_color_code="$1"
    shift
    local -a art_lines=("$@")
    local total_lines=${#art_lines[@]}

    # Extract base color number for final color
    local base_color="${final_color_code##*;}"
    local prefix=""
    [[ "$final_color_code" == *";"* ]] && prefix="${final_color_code%;*};"

    # Color sequence: gray -> red -> yellow -> green -> cyan -> blue -> magenta -> final color
    local -a color_sequence=(90 31 33 32 36 34 35 "$base_color")

    # First show in dark gray
    for ((i=0; i<total_lines; i++)); do
        colored_line=$(echo "${art_lines[$i]}" | sed 's/[(/|_\\,]/\x1b[90m&\x1b[0m/g')
        echo -e "$colored_line"
    done

    # Transition through colors
    for color in "${color_sequence[@]}"; do
        clear_lines "$total_lines"
        for ((i=0; i<total_lines; i++)); do
            colored_line=$(echo "${art_lines[$i]}" | sed "s/[(/|_\\,]/\x1b[${prefix}${color}m&\x1b[0m/g")
            echo -e "$colored_line"
        done
        sleep 0.15
    done

    # Final display
    clear_lines "$total_lines"
    display_final "$final_color_code" "${art_lines[@]}"
}

# Animation effects functions
pop_rainbow() {
    local color_code="$1"
    shift
    local -a art_lines=("$@")
    local total_lines=${#art_lines[@]}

    # First do the pop animation
    for ((i=0; i<total_lines; i++)); do
        # Print the new line
        colored_line=$(echo "${art_lines[$i]}" | sed "s/[(/|_\\,]/\x1b[${color_code}m&\x1b[0m/g")
        echo -e "$colored_line"
        sleep 0.2
    done

    # Short pause between effects
    sleep 0.3

    # Then do the rainbow animation
    local base_color="${color_code##*;}"
    local prefix=""
    [[ "$color_code" == *";"* ]] && prefix="${color_code%;*};"

    local -a color_sequence=(90 31 33 32 36 34 35 "$base_color")

    for color in "${color_sequence[@]}"; do
        clear_lines "$total_lines"
        for ((i=0; i<total_lines; i++)); do
            colored_line=$(echo "${art_lines[$i]}" | sed "s/[(/|_\\,]/\x1b[${prefix}${color}m&\x1b[0m/g")
            echo -e "$colored_line"
        done
        sleep 0.15
    done

    # Final display
    clear_lines "$total_lines"
    display_final "$color_code" "${art_lines[@]}"
}

pop_overlay_rainbow() {
    local color_code="$1"
    shift
    local -a art_lines=("$@")
    local total_lines=${#art_lines[@]}

    # Save cursor position
    echo -en "\033[s"

    # Print empty lines first to reserve space
    for ((i=0; i<total_lines; i++)); do
        echo
    done

    # Move back up
    echo -en "\033[${total_lines}A"

    # Show lines one by one
    for ((i=0; i<total_lines; i++)); do
        colored_line=$(echo "${art_lines[$i]}" | sed "s/[(/|_\\,]/\x1b[${color_code}m&\x1b[0m/g")
        echo -en "\r\033[K${colored_line}\n"
        sleep 0.2
    done

    # Short pause between effects
    sleep 0.3

    # Then do the rainbow animation
    local base_color="${color_code##*;}"
    local prefix=""
    [[ "$color_code" == *";"* ]] && prefix="${color_code%;*};"

    local -a color_sequence=(90 31 33 32 36 34 35 "$base_color")

    for color in "${color_sequence[@]}"; do
        clear_lines "$total_lines"
        for ((i=0; i<total_lines; i++)); do
            colored_line=$(echo "${art_lines[$i]}" | sed "s/[(/|_\\,]/\x1b[${prefix}${color}m&\x1b[0m/g")
            echo -e "$colored_line"
        done
        sleep 0.15
    done

    # Final display
    clear_lines "$total_lines"
    display_final "$color_code" "${art_lines[@]}"
}

# Function to print a single ASCII art piece
print_single_art() {
    local art_file="$1"
    local effect="$2"
    local color_spec="${3:-blue}"
    local show_config="${4:-}"

    # If show_config is enabled, display the configuration
    if [ "$show_config" = "show_config" ]; then
        echo -e "\033[90m# Configuration:"
        echo -e "# File: $art_file"
        echo -e "# Effect: $effect"
        echo -e "# Color: $color_spec\033[0m"
        echo
    fi

    # Split color_spec into color and variant (e.g., "blue:base" or just "blue")
    local color="${color_spec%:*}"
    local variant="base"
    if [[ "$color_spec" == *:* ]]; then
        variant="${color_spec#*:}"
    fi

    if [ ! -f "$art_file" ]; then
        echo "Error: ASCII art file not found at $art_file"
        return 1
    fi

    # Get color code
    local color_code=$(get_color_code "$color" "$variant")

    # Store the art in an array
    local -a art_lines
    mapfile -t art_lines < "$art_file"

    case "$effect" in
        "none")
            sleep 1
            display_final "$color_code" "${art_lines[@]}"
            sleep 1
            ;;
        "fade")
            fade_in "$color_code" "${art_lines[@]}"
            ;;
        "rainbow")
            rainbow "$color_code" "${art_lines[@]}"
            ;;
        "bounce")
            bounce_in "$color_code" "${art_lines[@]}"
            ;;
        "pop"|"pop_scroll")
            pop "$color_code" "${art_lines[@]}"
            ;;
        "pop_overlay")
            pop_overlay "$color_code" "${art_lines[@]}"
            ;;
        "pop_rainbow"|"pop_scroll_rainbow")
            pop_rainbow "$color_code" "${art_lines[@]}"
            ;;
        "pop_overlay_rainbow")
            pop_overlay_rainbow "$color_code" "${art_lines[@]}"
            ;;
        *)
            echo "Unknown effect: $effect, using none"
            display_final "$color_code" "${art_lines[@]}"
            ;;
    esac
}

# Main function to display sequence
display_sequence() {
    local config_file="$1"

    if [ ! -f "$config_file" ]; then
        echo "Usage: $0 config.txt"
        echo "Config file format:"
        echo "art/file1.txt effect color[:variant] [show_config]"
        echo "Available effects: none, fade, bounce, pop"
        echo "Available colors: blue, green, red, yellow, cyan, magenta, white"
        exit 1
    fi

    # Hide cursor
    tput civis

    # Read config file and display each art piece
    while read -r line || [ -n "$line" ]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # Parse the line, handling multiple spaces and comments
        read -r file effect color show_config _ <<< "$line"

        # Skip if we don't have the minimum required fields
        [[ -z "$file" || -z "$effect" || -z "$color" ]] && continue

        print_single_art "$file" "$effect" "$color" "$show_config"
    done < "$config_file"

    # Show cursor
    tput cnorm
}


# Call the main function with the config file
display_sequence "${1:-art-sequence.conf}"