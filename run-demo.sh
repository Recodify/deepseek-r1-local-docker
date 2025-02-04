#!/bin/bash

# Color codes
GREEN='\033[01;32m'
BLUE='\033[01;34m'
RESET='\033[00m'
WHITE='\033[00m'

# Timings
TYPING_SPEED=0.98
TYPING_PAUSE=$(echo "1 - $TYPING_SPEED" | bc)
COMMAND_PAUSE=0.2
STEP_PAUSE=1
STEP_INTRO_PAUSE=1.5
INITIAL_PAUSE=1
SECTION_PAUSE=0.5
TITLE_PAUSE=2
ANIMATION_PAUSE=0.6
CLEAR_PAUSE=0.02
TRANSITION_PAUSE=1.5

# Layout
DEFAULT_OFFSET=32
CURRENT_CARD_WIDTH=0

# Options
CLEANUP=false

while getopts "c" opt; do
    case $opt in
        c)
            CLEANUP=true
            ;;
    esac
done

create_padding() {
    local text="$1"
    local align="$2"
    local default_offset="${3:-}"
    local term_width
    local padding

    if [ -n "$default_offset" ]; then
        # Use fixed padding if offset is provided
        padding=""
        for ((i=0; i<default_offset; i++)); do
            padding+=" "
        done
    else
        # Calculate center padding based on text width
        term_width=$(tput cols)

        # Properly handle the text string with quotes to preserve spaces
        local stripped_text
        stripped_text=$(printf "%s" "$text" | sed 's/\x1B\[[0-9;]*[JKmsu]//g')
        local text_length=${#stripped_text}

        local padding_alignment_factor=2
        local left_margin_size=2
        local padding_size=0
        if [ "$align" = "left" ]; then
            padding_size=$((((term_width - $CURRENT_CARD_WIDTH) / 2  )+ $left_margin_size))
        else
           padding_size=$(( (term_width - text_length) / 2  ))
        fi


        # Ensure padding is not negative
        if ((padding_size < 0)); then
            padding_size=0
        fi

        padding=$(printf "%${padding_size}s" "")
    fi

    echo "$padding"
}

chat() {
    local text="$1"
    local typing_speed="${2:-$TYPING_SPEED}"
    local typing_pause=$(echo "1 - $typing_speed" | bc)
    local align="${3:-center}"
    local padding=$(create_padding "$text" "$align")

    printf "${padding}"
    echo -n "$text" | while IFS= read -r -n1 char; do
        printf "%s" "$char"
        sleep $typing_pause
    done
    printf "\n"

    sleep $ANIMATION_PAUSE
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
    local fragment="$2"
    local continue="$3"

    local padding=$(create_padding "$text")

    if [ "$continue" = "true" ]; then
        echo -e "\033[90m${text}\033[0m"
    else
        echo -e "${padding}\033[90m${text}\033[0m"
    fi

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
    local padding=$(create_padding "$text")

    # Green text with padding
    echo -e "${padding}\033[32m${text}\033[0m"
    sleep $ANIMATION_PAUSE
}

instruction() {
    local text="$1"
    local fragment="$2"
    local continue="$3"
    local align="${4:-center}"
    local padding=$(create_padding "$text" "$align")

    # White text with padding
    if [ "$fragment" = "true" ]; then
      echo -n -e "${padding}\033[37m${text}\033[0m"
    else
      echo -e "${padding}\033[37m${text}\033[0m"
    fi
    sleep $ANIMATION_PAUSE
}

flash_text() {
    local text="$1"
    local offset="${2:-$DEFAULT_OFFSET}"
    local flashes=4
    local flash_delay=0.3
    local padding=$(create_padding "$text")

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

transition_clear() {
    sleep $TRANSITION_PAUSE
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

set_terminal_dimensions() {
    local width="${1:-100}"
    local height="${2:-24}"

    # Check if we're already in the resized window
    if [ -z "$TERMINAL_RESIZED" ]; then
        # Launch new terminal and exit current one
        if [ -n "$GNOME_TERMINAL_SERVICE" ]; then
            gnome-terminal -- bash -c "TERMINAL_RESIZED=1 $0 $@"
            exit 0
        elif [ -n "$KONSOLE_VERSION" ]; then
            konsole -e bash -c "TERMINAL_RESIZED=1 $0 $@"
            exit 0
        fi
    fi

    # Try multiple resize methods
    if [ -t 0 ]; then  # Only attempt resize if running in a terminal
        # Method 1: ANSI escape sequence
        printf '\033[8;%d;%dt' "$height" "$width"

        # Method 2: tput if available
        if command -v tput >/dev/null 2>&1; then
            if [ "$TERM" != "dumb" ]; then
                tput cols "$width" >/dev/null 2>&1
                tput lines "$height" >/dev/null 2>&1
            fi
        fi

        # Method 3: resize command if available
        if command -v resize >/dev/null 2>&1; then
            resize -s "$height" "$width" > /dev/null 2>&1
        fi

        # Method 4: stty if available
        if command -v stty >/dev/null 2>&1; then
            stty rows "$height" cols "$width" 2>/dev/null
        fi
    fi

    # Verify dimensions - capture output in variables
    # Small delay to ensure terminal is resized before we process the check
    sleep 0.25
    local actual_width
    local actual_height
    actual_width=$(tput cols 2>/dev/null | tr -d '\n' || echo "$width")
    actual_height=$(tput lines 2>/dev/null | tr -d '\n' || echo "$height")

    # If dimensions don't match, show a note
    if [ "$actual_width" != "$width" ] || [ "$actual_height" != "$height" ]; then
        echo "Actual dimensions: $actual_width x $actual_height"
        echo "Desired dimensions: $width x $height"
        echo -e "\033[33m!NOTE: Terminal size could not be set automatically. For best experience, please resize your terminal to ${width}x${height}.\033[0m"
        sleep 20
    fi
}

titles() {
    # Clear the screen to start fresh
    clear

    # Set specific dimensions for each sequence
    ./demo/display-art-sequence.sh ./demo/recodify-sequence.conf 0.04 0.2
    transition_clear
    ./demo/display-art-sequence.sh ./demo/deepseek-sequence.conf 0.05 0.2
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

    chat  "========================================" 0.99
    flash_text  "Ready Player 2?"
    instruction "----------------------------------------"
    newline
    chat  "Just follow the steps shown next..."
    chat  "...and off you go. 💪"
    newline
    sleep $ANIMATION_PAUSE
    instruction "----------------------------------------"
    chat  "To the moon! 🚀 "
    chat  "========================================" 0.99

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
    # Show cursor again
    echo -en "\033[?25h"

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

    transition_clear
}

outro() {
    DEFAULT_OFFSET=23
    # Hide cursor
    echo -en "\033[?25l"

    newline
    newline
    local all_done_card_header="========================================================="
    CURRENT_CARD_WIDTH=${#all_done_card_header}
    chat    "$all_done_card_header" 0.995
    instruction  "All done!"
    instruction  "---------------------------------------------------------"
    newline
    chat   "That's it, you're all set up! "
    newline
    newline
    sleep $SECTION_PAUSE
    instruction  "You can now:" false false left
    newline
    instruction  "  - access the web ui: " true false left
    code         "http://localhost:8080" false true
    instruction  "  - chat interactively: " true false left
    code         "./scripts/interact.sh" false true
    instruction  "  - ask a question: " true false left
    code         "./scripts/prompt.sh 'What is 42?'" false true
    newline
    instruction  "---------------------------------------------------------"
    newline
    chat   "If you'd like to get in touch:" $TYPING_SPEED left
    newline
    instruction  " 🔗 https://github.com/Recodify/deepseek-r1-local-docker" false false left
    instruction  " 🧔 https://www.linkedin.com/in/sam-shiles-8494577" false false left
    instruction  " 🌐 https://recodify.co.uk" false false left
    newline
    instruction  "---------------------------------------------------------"
    chat   "Over and out! 👋 "
    chat   "=========================================================" 0.995
    newline
    # Show cursor again
    echo -en "\033[?25h"
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


set_terminal_dimensions 100 48

clear
titles
intro
command_intro
commands
outro
#clean_up
sleep 10