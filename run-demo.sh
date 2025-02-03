#!/bin/bash

# Color codes matching your bashrc
GREEN='\033[01;32m'
BLUE='\033[01;34m'
RESET='\033[00m'
WHITE='\033[00m'

# Sleep duration controls
TYPING_SPEED=0.98
TYPING_PAUSE=$(echo "1 - $TYPING_SPEED" | bc)
COMMAND_PAUSE=0.2
STEP_PAUSE=1
STEP_INTRO_PAUSE=1.5
INITIAL_PAUSE=1
SECTION_PAUSE=1.5
TITLE_PAUSE=2
ANIMATION_PAUSE=1
CLEAR_PAUSE=0.05

# Global offset for text alignment
DEFAULT_OFFSET=32
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
        # Update prompt with current directory - show only current dir name
        dir_display="$(basename "$current_dir")"
        [ "$current_dir" == "$HOME" ] && dir_display="~"
        # Show root (/) if in deepseek-r1-local-docker directory
        [ "$dir_display" == "deepseek-r1-local-docker-detached" ] && dir_display="~"
        PROMPT="${GREEN}altmans@openai${RESET}:${BLUE}${dir_display}${RESET}\$ "

        # Print prompt first
        echo -en "$PROMPT"

        # Simulate typing the command with backticks and special chars colorized
        for (( i=0; i<${#text}; i++ )); do
            if [[ "${text:$i:1}" == "\`" || "${text:$i:1}" == "Æ" ]]; then
                echo -en "${WHITE}${text:$i:1}"
            else
                echo -en "${WHITE}${text:$i:1}"
            fi
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
            elif [[ "$text" == *"prompt.sh"* ]]; then
                # Special handling for prompt.sh to show output character by character
                eval "$text" | while IFS= read -r -n1 char; do
                    echo -n "$char"
                    sleep 0.01  # Adjust this value to control output speed
                done
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
    local flashes=4
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

titles() {
    # Clear the screen to start fresh
    clear
    sleep $STEP_PAUSE

    # Set specific dimensions for each sequence
    ./demo/display-art-sequence.sh ./demo/recodify-sequence.conf
    sleep 1.5
    transition_clear
    ./demo/display-art-sequence.sh ./demo/deepseek-sequence.conf
    sleep 2
    transition_clear
}

intro() {
    #Intro

    newline
    newline
    newline
    newline
     # Hide cursor
    echo -en "\033[?25l"

    type_text_  "========================================" 0.98
    flash_text  "             Ready Player 2?"
    instruction "----------------------------------------"
    newline
    type_text_  "  Just follow the steps shown next..."
    type_text_  "  ...and off you go. 💪"
    newline
    sleep $ANIMATION_PAUSE
    instruction "----------------------------------------"
    type_text_  "              To the moon! 🚀 "
    type_text_  "========================================" 0.98

    # Show cursor again
    echo -en "\033[?25h"
    sleep 2
    transition_clear
}

command_intro() {
    newline
    sleep $ANIMATION_PAUSE
    newline
    sleep $ANIMATION_PAUSE
}

commands() {
    # Commands
    comment "First: create a working directory"
    simulate_typing "mkdir demo-deploy"

    comment "And: cd into it"
    simulate_typing "cd demo-deploy"

    comment "Then: clone the repository"
    simulate_typing "git clone https://github.com/Recodify/deepseek-r1-local-docker.git"

    comment "And: cd into it"
    simulate_typing "cd deepseek-r1-local-docker"

    comment "Next: start the docker containers"
    simulate_typing "make docker-up-cpu-only"
    note "1. This will take much longer the first time, as it's pulling the images."
    note "2. GPU support is recommended, see README.md for details."

    comment "Finaly: wait for everything to be ready"
    simulate_typing "./scripts/status-check.sh"
    note "This will take quite a long time the first time, as it's pulling the model."

    comment "Off we go: Feel free to ask a question!"
    simulate_typing "./scripts/prompt.sh \"What's the capital of France?\""

    sleep 2
    transition_clear
}

outro() {
    DEFAULT_OFFSET=23
    # Hide cursor
    echo -en "\033[?25l"

    newline
    newline
    type_text_   "=========================================================" 0.99
    instruction  "                        All done!"
    instruction  "---------------------------------------------------------"
    newline
    type_text_   "  That's it, you're all set up!"
    instruction  ""
    type_text_   "  You can now:"
    newline
    instruction  "   - access the web ui: "
    code         "      http://localhost:8080"
    newline
    instruction  "   - chat interactively: "
    code         "      ./scripts/interact.sh"
    newline
    instruction  "   - ask a question: "
    code         "      ./scripts/prompt.sh 'What is 42?'"
    newline
    instruction  "---------------------------------------------------------"
    newline
    type_text_   " If you'd like to get in touch:"
    newline
    instruction  " 🔗 https://github.com/Recodify/deepseek-r1-local-docker"
    instruction  " 🧔 https://www.linkedin.com/in/sam-shiles-8494577"
    instruction  " 🌐 https://recodify.co.uk"
    newline
    instruction  "---------------------------------------------------------"
    type_text_   "                      Over and out! 👋 "
    type_text_   "=========================================================" 0.99
    newline
    # Show cursor again
    echo -en "\033[?25h"
    sleep 2
    transition_clear
}

clean_up() {
    # Cleanup if requested
    if [ "$CLEANUP" = true ]; then
        cd demo-deploy
        cd deepseek-r1-local-docker
        docker compose down
        cd ..
        cd ..
        rm -rf demo-deploy
    fi
}

# At the start of the script, set initial size
set_terminal_dimensions() {
    local width="${1:-100}"
    local height="${2:-24}"
    if [[ "$TERM" == "xterm"* ]] || [[ "$TERM" == "screen"* ]]; then
        printf '\033[8;%d;%dt' "$height" "$width"
    elif command -v resize >/dev/null 2>&1; then
        resize -s "$height" "$width" > /dev/null
    fi
}

# Initial terminal setup
echo "Setting terminal dimensions"
set_terminal_dimensions 120 48

#clear
sleep 2
titles
intro
command_intro
commands
outro
clean_up