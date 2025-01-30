!#!/bin/bash

# Sleep duration controls
TYPING_SPEED=0.92
TYPING_PAUSE=$(echo "1 - $TYPING_SPEED" | bc)
COMMAND_PAUSE=0.2
STEP_PAUSE=1
STEP_INTRO_PAUSE=1.5
INITIAL_PAUSE=1
SECTION_PAUSE=1.5
ANIMATION_PAUSE=0.5

simulate_typing() {
    text=$1
    current_dir=$(pwd)
    # Update prompt with current directory
    dir_display="$(echo "~${current_dir#$HOME}" | sed 's/code\/deepseek-local-docker\///')"
    [ "$current_dir" == "$HOME" ] && dir_display="~"
    PROMPT="${GREEN}altmans@openai${RESET}:${BLUE}${dir_display}${RESET}\$ "

    # Print prompt first
    echo -en "$PROMPT"

    # Simulate typing the command
    for (( i=0; i<${#text}; i++ )); do
        echo -en "${WHITE}${text:$i:1}"
        sleep $TYPING_PAUSE
    done
    echo -e "${RESET}"
    sleep $COMMAND_PAUSE

    # For cd commands, actually change the directory in the parent shell
    if [[ "$text" == cd* ]]; then
        # Execute cd command directly
        eval "$text"
    else
        # For status-check.sh, execute it directly to preserve interactive output
        if [[ "$text" == *"status-check.sh"* ]]; then
            eval "$text"
        elif [[ "$text" == "make docker-up-cpu-only" ]]; then
            # Filter the make command output to show only the important status messages
            output=$(eval "$text" 2>&1 | grep -E "Container|Network|Starting|Created|Done")
            if [ ! -z "$output" ]; then
                sleep $COMMAND_PAUSE
                while IFS= read -r line; do
                    echo -e "$line"
                    sleep $TYPING_PAUSE
                done <<< "$output"
            fi
        else
            # For other commands, execute and capture output
            output=$(eval "$text" 2>&1)
            if [ ! -z "$output" ]; then
                sleep $COMMAND_PAUSE
                while IFS= read -r line; do
                    echo -e "$line"
                    sleep $TYPING_PAUSE
                done <<< "$output"
            fi
        fi
    fi
    sleep $STEP_PAUSE
}


clear
sleep 3
simulate_typing "./run-demo.sh"