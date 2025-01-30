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
    local offset="${1:-0}"  # Default offset of 0 if not provided
    local text="$2"
    local padding=""
    
    # Create the padding string
    for ((i=0; i<offset; i++)); do
        padding+=" "
    done
    
    # Green text with padding
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
    local offset="${1:-0}"  # Default offset of 0 if not provided
    local text="$2"
    local padding=""
    
    # Create the padding string
    for ((i=0; i<offset; i++)); do
        padding+=" "
    done
    
    # Green text with padding
    echo -e "${padding}\033[32m${text}\033[0m"
    sleep $ANIMATION_PAUSE
}

instruction() {
    local offset="${1:-0}"  # Default offset of 0 if not provided
    local text="$2"
    local padding=""
    
    # Create the padding string
    for ((i=0; i<offset; i++)); do
        padding+=" "
    done
    
    # White text with padding
    echo -e "${padding}\033[37m${text}\033[0m"
    sleep $ANIMATION_PAUSE
}

flash_text() {
    local offset="${1:-0}"  # Default offset of 0 if not provided
    local text="$2"
    local flashes=5
    local flash_delay=0.3
    local padding=""
    
    # Create the padding string
    for ((i=0; i<offset; i++)); do
        padding+=" "
    done

    # Save cursor position
    echo -en "\033[s"

    for ((i=1; i<=$flashes; i++)); do
        # Show text in green with padding
        echo -en "${padding}\033[32m${text}\033[0m"
        sleep $flash_delay
        # Restore cursor and clear line
        echo -en "\033[u\033[K"
        sleep $flash_delay
        # Restore cursor again
        echo -en "\033[u"
    done

    # Final display of text
    echo -e "${padding}\033[32m${text}\033[0m"
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
    
    # Create transition effect
    for ((i=1; i<=$current_row; i++)); do
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

# Clear the screen to start fresh
clear
sleep $STEP_PAUSE

# Titles
#./demo/display-art-sequence.sh ./demo/recodify-sequence.conf
#transition_clear
#sleep $TITLE_PAUSE

#./demo/display-art-sequence.sh ./demo/deepseek-sequence.conf
#transition_clear
#sleep $TITLE_PAUSE
# Intro

newline
newline
newline
newline
information 70 "========================================"
flash_text 70 "            Ready Player 1?"
instruction 70 "----------------------------------------"
information 70 ""
instruction 70 "  Just follow the steps shown next..."
instruction 70 "  ...and off you go! 🚀"
instruction 70 ""
instruction 70 "----------------------------------------"
instruction 70 "             Let's go 💪 " 
information 70 "========================================"
newline
newline
newline

# sleep $SECTION_PAUSE
# transition_clear

# newline
# sleep $ANIMATION_PAUSE
# newline
# sleep $ANIMATION_PAUSE
# newline
# sleep $ANIMATION_PAUSE
# newline

# # Commands
# comment "First: create a working directory"
# simulate_typing "mkdir demo-deploy"

# comment "And: cd into it"
# simulate_typing "cd demo-deploy"

# comment "Then: clone the repository"
# simulate_typing "git clone https://github.com/Recodify/deepseek-r1-local-docker.git"

# comment "And: cd into it"
# simulate_typing "cd deepseek-r1-local-docker"

# comment "Next: start the docker containers"
# simulate_typing "make docker-up-cpu-only"
# note "This will take much longer the first time you do it as it's pulling the images, I'm cheating."
# note "Also, you'll almost certainly want to enable GPU support, but that's up to you, see README.md for details."

# comment "Finaly: wait for everything to be ready"
# simulate_typing "./scripts/status-check.sh"
# note "This will take quite a long time the first time you do it as it's pulling the model, I'm cheating."

# comment "Off we go: Feel free to ask a question!"
# simulate_typing "docker exec -it deepseek-ollama ollama run deepseek-r1:1.5b 'What is the capital of France?'"
# sleep $SECTION_PAUSE
# transition_clear

# Outro
sleep $STEP_INTRO_PAUSE
newline
newline
information 70 "==============================================================="
information 70 "                           DONE!" 
instruction 70 "---------------------------------------------------------------" 
newline
instruction 70 "   That's it! You're all set up!" 
instruction 70 "" 
instruction 70 "   You can now:" 
newline
instruction 70 "    - access the web ui: "
code 70                "http://localhost:8080"
newline
instruction 70 "    - chat interactively: "
code 70                  "./scripts/interact.sh"
newline
instruction 70 "    - ask a question: "
code 70                "./scripts/prompt.sh 'What is 42?'"
newline
instruction 70 "---------------------------------------------------------------" 
instruction 70 "" 
instruction 70 "    🔗 https://github.com/Recodify/deepseek-r1-local-docker" 
instruction 70 "    🧔 https://www.linkedin.com/in/sam-shiles-8494577" 
instruction 70 "    🌐 https://recodify.co.uk" 
instruction 70 "" 
instruction 70 "                     👋 Over and out!" 
information 70 "===============================================================" 
newline
#transition_clear