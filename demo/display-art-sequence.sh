#!/bin/bash

FRAME_PAUSE="${2:-0.1}"
EFFECT_TRANSITION_PAUSE="${3:-0.3}"
NEXT_IMAGE_PAUSE="${4:-0.5}"
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
    local color="${1:-}"
    local variant="${2:-base}"

    # If no color specified, return empty string to preserve original colors
    [[ -z "$color" ]] && return

    # Base colors (30-37)
    local -A base_colors=(
        ["black"]="30" ["red"]="31" ["green"]="32" ["yellow"]="33"
        ["blue"]="34" ["magenta"]="35" ["cyan"]="36" ["white"]="37"
    )

    # Bright colors (90-97)
    local -A bright_colors=(
        ["black"]="1;30" ["red"]="1;31" ["green"]="1;32" ["yellow"]="1;33"
        ["blue"]="1;34" ["magenta"]="1;35" ["cyan"]="1;36" ["white"]="1;37"
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

# Add this new function after the get_color_code function
calculate_padding() {
    local -a art_lines=("$@")
    local max_width=0
    local term_width

    # Get terminal width
    term_width=$(tput cols)

    # Find the maximum width of the art
    for line in "${art_lines[@]}"; do
        # Strip ANSI escape sequences and count actual characters
        local stripped_line=$(echo -e "$line" | sed 's/\x1B\[[0-9;]*[JKmsu]//g')
        local line_length=${#stripped_line}
        if ((line_length > max_width)); then
            max_width=$line_length
        fi
    done

    # Calculate padding needed to center
    local padding=$(( (term_width - max_width) / 2 ))

    # Ensure padding is not negative
    if ((padding < 0)); then
        padding=0
    fi

    echo "$padding"
}

# Animation effects functions
fade_in() {
    local color_code="$1"
    shift
    local -a art_lines=("$@")
    local total_lines=${#art_lines[@]}
    local padding=$(calculate_padding "${art_lines[@]}")
    local padding_spaces=$(printf "%${padding}s" "")

    # Extract base color number for fading
    local base_color="${color_code##*;}"
    local prefix=""
    [[ "$color_code" == *";"* ]] && prefix="${color_code%;*};"

    # First show in dark gray
    for ((i=0; i<total_lines; i++)); do
        colored_line=$(echo "${art_lines[$i]}" | sed 's/[(/|_\\,]/\x1b[90m&\x1b[0m/g')
        echo -e "${padding_spaces}${colored_line}"
    done

    # Fade through shades to final color
    for shade in 90 $(( base_color - 1 )) $base_color; do
        clear_lines "$total_lines"
        for ((i=0; i<total_lines; i++)); do
            colored_line=$(echo "${art_lines[$i]}" | sed "s/[(/|_\\,]/\x1b[${prefix}${shade}m&\x1b[0m/g")
            echo -e "${padding_spaces}${colored_line}"
        done
        sleep $EFFECT_TRANSITION_PAUSE
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
    local padding=$(calculate_padding "${art_lines[@]}")
    local padding_spaces=$(printf "%${padding}s" "")
    local padding_vertical=5
    local total_height=$((total_lines + padding_vertical))

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
    local padding=$(calculate_padding "${art_lines[@]}")
    local padding_spaces=$(printf "%${padding}s" "")

    # Start from the bottom, showing one line at a time
    for ((i=0; i<total_lines; i++)); do
        # Print the new line
        colored_line=$(echo "${art_lines[$i]}" | sed "s/[(/|_\\,]/\x1b[${color_code}m&\x1b[0m/g")
        echo -e "${padding_spaces}${colored_line}"
        sleep $FRAME_PAUSE
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
    pop "$color_code" "${art_lines[@]}"
}

# Modify the display_final function to include centering
display_final() {
    local color_code="$1"
    shift
    local -a art_lines=("$@")
    local padding=$(calculate_padding "${art_lines[@]}")
    local padding_spaces=$(printf "%${padding}s" "")

    # Only apply coloring if a color_code is specified
    if [[ -n "$color_code" ]]; then
        for line in "${art_lines[@]}"; do
            colored_line=$(echo "$line" | sed "s/[(/|_\\,]/\x1b[${color_code}m&\x1b[0m/g")
            echo -e "${padding_spaces}${colored_line}"
        done
    else
        # Print lines as-is to preserve existing ANSI colors
        for line in "${art_lines[@]}"; do
            echo -e "${padding_spaces}${line}"
        done
    fi
}

# Animation effects functions
rainbow() {
    local final_color_code="$1"
    shift
    local -a art_lines=("$@")
    local padding=$(calculate_padding "${art_lines[@]}")
    local padding_spaces=$(printf "%${padding}s" "")
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
        echo -e "${padding_spaces}${colored_line}"
    done

    # Transition through colors
    for color in "${color_sequence[@]}"; do
        clear_lines "$total_lines"
        for ((i=0; i<total_lines; i++)); do
            colored_line=$(echo "${art_lines[$i]}" | sed "s/[(/|_\\,]/\x1b[${prefix}${color}m&\x1b[0m/g")
            echo -e "${padding_spaces}${colored_line}"
        done
        sleep $FRAME_PAUSE
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
        sleep $FRAME_PAUSE
    done

    # Short pause between effects
    sleep $EFFECT_TRANSITION_PAUSE

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
        sleep $FRAME_PAUSE
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
    local padding=$(calculate_padding "${art_lines[@]}")
    local padding_spaces=$(printf "%${padding}s" "")

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
        echo -e "${padding_spaces}${colored_line}"
        sleep $FRAME_PAUSE
    done

    # Short pause between effects
    sleep $EFFECT_TRANSITION_PAUSE

    # Then do the rainbow animation
    local base_color="${color_code##*;}"
    local prefix=""
    [[ "$color_code" == *";"* ]] && prefix="${color_code%;*};"

    local -a color_sequence=(90 31 33 32 36 34 35 "$base_color")

    for color in "${color_sequence[@]}"; do
        clear_lines "$total_lines"
        for ((i=0; i<total_lines; i++)); do
            colored_line=$(echo "${art_lines[$i]}" | sed "s/[(/|_\\,]/\x1b[${prefix}${color}m&\x1b[0m/g")
            echo -e "${padding_spaces}${colored_line}"
        done
        sleep $FRAME_PAUSE
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

    # If show_config is enabled, display the configuration
    if [ "$show_config" = "show_config" ]; then
        echo -e "\033[90m# Configuration:"
        echo -e "# File: $art_file"
        echo -e "# Effect: $effect"
        echo -e "# Color: $color_spec\033[0m"

        echo -e "$color_code"
    fi

    # Store the art in an array
    local -a art_lines
    mapfile -t art_lines < "$art_file"

    case "$effect" in
        "raw")
            display_final "" "${art_lines[@]}"
            ;;
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
        sleep $NEXT_IMAGE_PAUSE
    done < "$config_file"

    # Show cursor
    tput cnorm
}



# Call the main function with the config file
display_sequence "${1:-art-sequence.conf}"
