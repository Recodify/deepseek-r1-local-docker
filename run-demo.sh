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

comment() {
    # Light gray text
    echo ""
    echo -e "\033[90m# $1\033[0m"
    sleep $ANIMATION_PAUSE
}

code() {
    # Light gray text
    echo ""
    echo -e "\033[90m $1\033[0m"
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
    # Green text, no prefix
    echo -e "\033[32m$1\033[0m"
    sleep $ANIMATION_PAUSE
}

instruction() {
    # White text, no prefix
    echo -e "\033[37m$1\033[0m"
    sleep $ANIMATION_PAUSE
}

flash_text() {
    local text="$1"
    local flashes=5
    local flash_delay=0.3

    # Save cursor position
    echo -en "\033[s"

    for ((i=1; i<=$flashes; i++)); do
        # Show text in green
        echo -en "\033[32m$text\033[0m"
        sleep $flash_delay
        # Restore cursor and clear line
        echo -en "\033[u\033[K"
        sleep $flash_delay
        # Restore cursor again
        echo -en "\033[u"
    done

    # Final display of text
    echo -e "\033[32m$text\033[0m"
    sleep $ANIMATION_PAUSE
}

# Clear the screen to start fresh

clear
sleep $STEP_PAUSE

# Titles
./demo/display-art-sequence.sh ./demo/intro-sequence.conf

# Intro

newline
newline
newline
newline
information "                                                                                   ========================================"
flash_text "                                                                                                Ready Player 1?"
instruction "                                                                                   ----------------------------------------"
information ""
instruction "                                                                                    Just follow the steps shown next..."
instruction "                                                                                      ...and off you go! 🚀"
instruction ""
instruction "                                                                                   ----------------------------------------"
instruction ""
instruction "                                                                                                  Let's go 💪 "
information "                                                                                   ========================================"
newline
newline
newline

sleep $SECTION_PAUSE
clear

newline
sleep $ANIMATION_PAUSE
newline
sleep $ANIMATION_PAUSE
newline
sleep $ANIMATION_PAUSE
newline

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
note "This will take much longer the first time you do it as it's pulling the images, I'm cheating."
note "Also, you'll almost certainly want to enable GPU support, but that's up to you, see README.md for details."

comment "Finaly: wait for everything to be ready"
simulate_typing "./scripts/status-check.sh"
note "This will take quite a long time the first time you do it as it's pulling the model, I'm cheating."

comment "Off we go: Feel free to ask a question!"
simulate_typing "docker exec -it deepseek-ollama ollama run deepseek-r1:1.5b 'What is the capital of France?'"
sleep $SECTION_PAUSE
clear

# Outro
sleep $STEP_INTRO_PAUSE
newline
newline
information "                                                                      ==============================================================="
information "                                                                                                 DONE!"
instruction "                                                                      ---------------------------------------------------------------"
information ""
instruction "                                                                        That's it! You're all set up!"
instruction ""
instruction "                                                                        You can now access the webui at:"
code        "                                                                        http://localhost:8080"
instruction ""
instruction "                                                                        Or, for an interactive shell:"
code        "                                                                        $ docker exec -it deepseek-ollama ollama run deepseek-r1:1.5b"
instruction ""
instruction "                                                                      ---------------------------------------------------------------"
instruction ""
instruction "                                                                          🔗 https://github.com/Recodify/deepseek-r1-local-docker"
instruction "                                                                          🧔 https://www.linkedin.com/in/sam-shiles-8494577"
instruction "                                                                          🌐 https://recodify.co.uk"
instruction ""
instruction "                                                                                           👋 Over and out!"
information "                                                                      ==============================================================="
newline