#!/bin/bash

# Color codes matching your bashrc
GREEN='\033[01;32m'
BLUE='\033[01;34m'
RESET='\033[00m'
WHITE='\033[00m'

# Sleep duration controls
TYPING_SPEED=0.92
TYPING_PAUSE=$(echo "1 - $TYPING_SPEED" | bc)
COMMAND_PAUSE=0.2
STEP_PAUSE=1
STEP_INTRO_PAUSE=1.5
INITIAL_PAUSE=1
SECTION_PAUSE=1.5
TITLE_PAUSE=2
ANIMATION_PAUSE=0.5
CLEAR_PAUSE=0.05

# Global offset for text alignment
DEFAULT_OFFSET=45
DONE_OFFSET=65

# Add these near the top of the file, after other variable declarations
CLEANUP=false
while getopts "c" opt; do
    case $opt in
        c)
            CLEANUP=true
            ;;
    esac
done

# Shared function to create padding
create_padding() {
    local offset="${1:-$DEFAULT_OFFSET}"
    local padding=""
    for ((i=0; i<offset; i++)); do
        padding+=" "
    done
    echo "$padding"
}

type_text_() {
    local text="$1"
    local typing_speed="${2:-$TYPING_SPEED}"
    simulate_typing "$text" false "$typing_speed"
}

simulate_typing() {
    local text="$1"
    local execute_command="${2:-true}"  # Default to true for backward compatibility
    local typing_speed="${3:-$TYPING_SPEED}"  # Default to global TYPING_SPEED if not provided
    local typing_pause=$(echo "1 - $typing_speed" | bc)
    
    if [ "$execute_command" = true ]; then
        local current_dir=$(pwd)
        # Update prompt with current directory
        dir_display="$(echo "~${current_dir#$HOME}" | sed 's/code\/deepseek-r1-local-docker\///')"
        [ "$current_dir" == "$HOME" ] && dir_display="~"
        PROMPT="${GREEN}altmans@openai${RESET}:${BLUE}${dir_display}${RESET}\$ "

        # Print prompt first
        echo -en "$PROMPT"

        # Simulate typing the command
        for (( i=0; i<${#text}; i++ )); do
            echo -en "${WHITE}${text:$i:1}"
            sleep $typing_pause
        done
        echo -e "${RESET}"
        sleep $COMMAND_PAUSE

        # Command execution logic...
        if [[ "$text" == cd* ]]; then
            eval "$text"
        else
            if [[ "$text" == *"status-check.sh"* ]]; then
                eval "$text"
            elif [[ "$text" == "make docker-up-cpu-only" ]]; then
                output=$(eval "$text" 2>&1 | grep -E "Container|Network|Starting|Created|Done")
                if [ ! -z "$output" ]; then
                    sleep $COMMAND_PAUSE
                    while IFS= read -r line; do
                        echo -e "$line"
                        sleep $typing_pause
                    done <<< "$output"
                fi
            else
                output=$(eval "$text" 2>&1)
                if [ ! -z "$output" ]; then
                    sleep $COMMAND_PAUSE
                    while IFS= read -r line; do
                        echo -e "$line"
                        sleep $typing_pause
                    done <<< "$output"
                fi
            fi
        fi
    else
        # For non-command text, use padding and simulate typing
        local padding=$(create_padding "$DEFAULT_OFFSET")
        echo -en "$padding"
        for (( i=0; i<${#text}; i++ )); do
            echo -en "${WHITE}${text:$i:1}"
            sleep $typing_pause
        done
        echo -e "${RESET}"
    fi
    if [ "$execute_command" = true ]; then
        sleep $STEP_PAUSE
    fi
}

comment() {
    # Light gray text
    echo ""
    echo -e "\033[90m# $1\033[0m"
    sleep $ANIMATION_PAUSE
}

code() {    
    local text="$1"
    local offset="${2:-$DEFAULT_OFFSET}"
    local padding=$(create_padding "$offset")
    
    # Gray text with padding
    echo -e "${padding}\033[90m${text}\033[0m"
    sleep $ANIMATION_PAUSE
}

note() {
    # Yellow text with '!' prefix
    echo -e "\033[33m!NOTE: $1\033[0m"
    sleep $ANIMATION_PAUSE
}

newline() {
    echo ""
}

information() {    
    local text="$1"
    local offset="${2:-$DEFAULT_OFFSET}"
    local padding=$(create_padding "$offset")
    
    # Green text with padding
    echo -e "${padding}\033[32m${text}\033[0m"
    sleep $ANIMATION_PAUSE
}

instruction() {
    local text="$1"
    local offset="${2:-$DEFAULT_OFFSET}"    
    local padding=$(create_padding "$offset")
    
    # White text with padding
    echo -e "${padding}\033[37m${text}\033[0m"
    sleep $ANIMATION_PAUSE
}

flash_text() {    
    local text="$1"
    local offset="${2:-$DEFAULT_OFFSET}"
    local flashes=5
    local flash_delay=0.3
    local padding=$(create_padding "$offset")
    
    # Save cursor position
    echo -en "\033[s"
    for ((i=1; i<=$flashes; i++)); do
        # Show text in green with padding
        echo -en "${padding}\033[37m${text}\033[0m"
        sleep $flash_delay
        # Restore cursor and clear line
        echo -en "\033[u\033[K"
        sleep $flash_delay
        # Restore cursor again
        echo -en "\033[u"
    done

    # Final display of text
    echo -e "${padding}\033[37m${text}\033[0m"    
    
    sleep $ANIMATION_PAUSE
}

# Add this new function after the other function definitions
transition_clear() {
    # Save cursor position
    echo -en "\033[s"
    
    # Get current cursor position (row)
    local current_row
    IFS=';' read -sdR -p $'\E[6n' ROW COL
    current_row=${ROW#*[}
    
    # Create transition effect from bottom to top
    for ((i=$current_row; i>=1; i--)); do
        # Move cursor to line i
        echo -en "\033[${i};1H"
        # Draw a line of underscores across the terminal
        printf '%*s' "${COLUMNS:-$(tput cols)}" '' | tr ' ' '_'
        sleep $CLEAR_PAUSE
        # Clear the line
        echo -en "\033[${i};1H"
        printf '%*s' "${COLUMNS:-$(tput cols)}" '' | tr ' ' ' '
    done
    
    # Actually clear the screen and reset cursor
    clear
    echo -en "\033[H"
}

clear
sleep 2

# Commands
comment "Start an interactive chat:"
#simulate_typing "./scripts/interact.sh \"What's the capital of France?\""

