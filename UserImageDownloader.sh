#!/bin/bash

# Check for required tools
command -v jq >/dev/null 2>&1 || { echo "jq is required but it's not installed. Aborting." >&2; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "curl is required but it's not installed. Aborting." >&2; exit 1; }

# Check for parameters
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <directory> <user_id1> [<user_id2> ...]"
    exit 1
fi

# Directory name
DIR_NAME="$1"
shift

# Create directory if not exists, ensure it's created next to the script
SCRIPT_DIR=$(dirname "$0")
TARGET_DIR="$SCRIPT_DIR/$DIR_NAME"
mkdir -p "$TARGET_DIR"

# Log file
LOG_FILE="$SCRIPT_DIR/UserImageDownloader.log"

# Get current git branch name
BRANCH_NAME=$(git branch --show-current)

# Function to log messages
log_message() {
    local MESSAGE="$1"
    local TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S.%N")
    echo "$TIMESTAMP - $MESSAGE" >> "$LOG_FILE"
}

# Function to download user image
download_user_image() {
    USER_ID="$1"
    RESPONSE=$(curl -s "https://reqres.in/api/users/$USER_ID")
    DATA=$(echo "$RESPONSE" | jq -r '.data')

    if [ "$DATA" != "null" ]; then
        AVATAR_URL=$(echo "$RESPONSE" | jq -r '.data.avatar')
        FIRST_NAME=$(echo "$RESPONSE" | jq -r '.data.first_name')
        LAST_NAME=$(echo "$RESPONSE" | jq -r '.data.last_name')
        FILE_NAME="$TARGET_DIR/${USER_ID}_${FIRST_NAME}_${LAST_NAME}.jpg"
        curl -s "$AVATAR_URL" -o "$FILE_NAME"
        if [ $? -eq 0 ]; then
            log_message "Downloaded $FILE_NAME"
        else
            log_message "Failed to download $FILE_NAME"
        fi
    else
        log_message "User ID $USER_ID not found."
    fi
}

# Log script start
log_message "Script started by user $(whoami) on branch $BRANCH_NAME."

# Loop through all user IDs and download images
for USER_ID in "$@"; do
    download_user_image "$USER_ID"
done

# Log script end
log_message "Script completed."
