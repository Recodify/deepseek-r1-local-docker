#!/bin/bash

# Get container name from environment variable or use default
CONTAINER_NAME=${OLLAMA_CONTAINER_NAME:-deepseek-ollama}
WEBUI_PORT=${WEBUI_PORT:-8080}

# ANSI color codes - fix escaping
GREEN='\e[32m'
RED='\e[31m'
BLUE='\e[34m'
NC='\e[0m'

echo -e "\n${BLUE}Starting DeepSeek status check...${NC}"
echo -e "Checking container: ${CONTAINER_NAME}"
echo -e "WebUI port: ${WEBUI_PORT}\n"

# Function to check if container is running
check_container() {
    echo -n "Checking container status... "
    # Try up to 30 times (30 seconds total)
    for i in {1..30}; do
        if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            echo -e "${GREEN}running${NC}"
            return 0
        fi
        echo -ne "\rChecking container status... (attempt ${i}/30)   "
        sleep 1
    done
    echo -e "\n${RED}Error:${NC} Container '${CONTAINER_NAME}' is not running after 30 seconds"
    echo "Please check if the container is started with 'docker ps'"
    return 1
}

# Check if container is running first
if ! check_container; then
    exit 1
fi

# Function to show progress bar using simple ASCII characters
show_progress() {
    local percentage=$1
    local width=20
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))

    printf "["
    printf "%${filled}s"
    printf "%${empty}s"
    printf "]"
}

# Function to show animated spinner when no progress
show_spinner() {
    local animation_state=$1
    local spinner="-\|/"
    echo -n "${spinner:animation_state:1}"
}

# Function to check if WebUI is responding
check_webui() {
    # Try up to 30 times (30 seconds total)
    for i in {1..30}; do
        if curl -s -f http://localhost:${WEBUI_PORT} >/dev/null; then
            return 0
        fi
        sleep 2
    done
    return 1
}

# Initialize variables
last_percentage=""
animation_counter=0

while true; do
    # Check if server is ready
    if docker logs $CONTAINER_NAME 2>&1 | grep -F "🚀 Ollama is ready!" > /dev/null; then
        # Check WebUI status first
        echo -n "Checking WebUI... "
        if check_webui; then
            webui_status="running $(echo -e "${GREEN}✓${NC}")"
            echo -e "${GREEN}ready${NC}"
        else
            webui_status="not responding $(echo -e "${RED}✗${NC}")"
            echo -e "${RED}not responding${NC}"
        fi

        # Extract and display the details section
        echo -e "\n${GREEN}All checks complete!${NC}\n"
        # Only show the last occurrence of each status line
        docker logs $CONTAINER_NAME 2>&1 | sed -n '/^   - /p' | awk '!seen[$0]++' | tail -n 3 | sed "s/✓/$(echo -e "${GREEN}✓${NC}")/"
        echo -e "   - WebUI status: $webui_status"

        # Exit with appropriate code based on WebUI status
        if [[ "$webui_status" == *"not responding"* ]]; then
            exit 1
        fi
        exit 0
    else
        if [ -z "$checking_message_shown" ]; then
            echo "Checking Ollama server status..."
            checking_message_shown=1
        fi

        # Extract progress information using grep and sed
        progress_line=$(docker logs $CONTAINER_NAME 2>&1 | grep -F "pulling" | tail -n 1)

        if [ ! -z "$progress_line" ]; then
            # Extract percentage
            percentage=$(echo "$progress_line" | grep -o '[0-9]\+%' | head -n 1 | tr -d '%')

            # Extract current/total size
            sizes=$(echo "$progress_line" | grep -o '[0-9.]\+ [MG]B/[0-9.]* [MG]B' | head -n 1)

            # Extract speed
            speed=$(echo "$progress_line" | grep -o '[0-9.]\+ [MG]B/s' | head -n 1)

            if [ ! -z "$percentage" ] && [ "$percentage" != "$last_percentage" ]; then
                echo -ne "\r$(show_progress $percentage) ${percentage}% | ${sizes} | ${speed}      \r"
                last_percentage=$percentage

                # If we reach 100%, continue checking for server listening
                if [ "$percentage" = "100" ]; then
                    echo -e "\nDownload complete, waiting for server to start..."
                fi
            else
                # Show spinner when percentage hasn't changed
                echo -ne "\r[$(show_spinner $((animation_counter % 4)))] Waiting...      \r"
                ((animation_counter++))
            fi
        else
            # Show spinner when no progress line is found
            echo -ne "\r[$(show_spinner $((animation_counter % 4)))] Waiting...      \r"
            ((animation_counter++))
        fi
    fi

    # Wait a shorter time for smoother animation
    sleep 0.1
done