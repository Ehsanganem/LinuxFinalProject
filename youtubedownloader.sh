#!/bin/bash

# Check for required tools
command -v python3 >/dev/null 2>&1 || { echo "Python3 is required but it's not installed. Aborting." >&2; exit 1; }
command -v pip3 >/dev/null 2>&1 || { echo "pip3 is required but it's not installed. Aborting." >&2; exit 1; }
command -v mpv >/dev/null 2>&1 || { echo "mpv is required but it's not installed. Install it using 'sudo apt install mpv'. Aborting." >&2; exit 1; }

# Function to list playlists and their contents
list_playlists() {
    local playlists=("$@")

    if [ ${#playlists[@]} -eq 0 ]; then
        playlists=($(cut -d ' ' -f 2 playlist_index.txt))
    fi

    for playlist_name in "${playlists[@]}"; do
        folder_path=$(grep "$playlist_name" playlist_index.txt | cut -d ' ' -f 1 | tr '\n' ' ' | sed 's/ $//')

        if [ -z "$folder_path" ]; then
            echo "Playlist $playlist_name not found in index."
            continue
        fi

        IFS=' ' read -r -a folder_paths <<< "$folder_path"

        for folder in "${folder_paths[@]}"; do
            if [ ! -d "$folder" ]; then
                echo "Folder path $folder does not exist."
                continue
            fi

            echo "Playlist: $playlist_name"
            echo "Folder Path: $folder"
            echo "Files:"
            find "$folder" -type f \( -name "*.mp3" -o -name "*.mp4" \) -exec echo "  {}" \;
            echo
        done
    done
}

# Function to create and play m3u playlists
play_playlists() {
    local playlists=("$@")
    local combined_name
    local m3u_file
    combined_name=$(IFS=_; echo "${playlists[*]}")
    m3u_file="${combined_name}_playlist.m3u"

    > "$m3u_file"

    for playlist_name in "${playlists[@]}"; do
        folder_path=$(grep "$playlist_name" playlist_index.txt | cut -d ' ' -f 1 | tr '\n' ' ' | sed 's/ $//')

        if [ -z "$folder_path" ]; then
            echo "Playlist $playlist_name not found in index."
            continue
        fi

        IFS=' ' read -r -a folder_paths <<< "$folder_path"

        for folder in "${folder_paths[@]}"; do
            if [ ! -d "$folder" ]; then
                echo "Folder path $folder does not exist."
                continue
            fi

            find "$folder" -type f \( -name "*.mp3" -o -name "*.mp4" \) >> "$m3u_file"
        done
    done

    if [ ! -s "$m3u_file" ]; then
        echo "No media files found in the specified playlists."
        rm "$m3u_file"
        exit 1
    fi

    # Play the m3u playlist using mpv
    mpv "$m3u_file"

    # Clean up the m3u file after playback
    rm "$m3u_file"
}

# Check if the play flag is used
if [ "$1" == "--play" ]; then
    shift
    play_playlists "$@"
    exit 0
fi

# Check if the list flag is used
if [ "$1" == "--list" ]; then
    shift
    list_playlists "$@"
    exit 0
fi

# Function to display progress animation
show_progress() {
    pid=$1
    delay=0.1
    spinstr='|/-\'
    while ps -p $pid > /dev/null; do
        temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Function to check parameter validity
check_params() {
    if [ -z "$URL" ]; then
        echo "Error: URL is missing"
        deactivate || exit 1
    fi
    if [ -z "$FILENAME" ]; then
        echo "Error: Filename is missing"
        deactivate || exit 1
    fi
    if [ -z "$FOLDERPATH" ]; then
        echo "Error: Folder path is missing"
        deactivate || exit 1
    fi
    if [ "$ISAUDIO" == "false" ] && [ -z "$RESOLUTION" ]; then
        echo "Error: Resolution is missing for video"
        deactivate || exit 1
    fi
}

# Function to add media files to a playlist
add_to_playlist() {
    local url=$1
    local folder=$2
    local file=$3
    local res=$4

    # Determine if the file is audio or video based on the filename extension
    if [[ "$file" == *.mp3 ]]; then
        is_audio="true"
        res="none"
    else
        is_audio="false"
    fi

    # Print parsed parameters for debugging
    echo "URL: $url"
    echo "Filename: $file"
    echo "Folder Path: $folder"
    echo "Resolution: $res"
    echo "Is Audio Only: $is_audio"

    # Check the validity of parameters
    URL=$url
    FILENAME=$file
    FOLDERPATH=$folder
    ISAUDIO=$is_audio
    RESOLUTION=$res
    check_params

    # Ensure the folder path exists
    if [ ! -d "$folder" ]; then
        mkdir -p "$folder"
    fi

    # Get the playlist name based on the folder path
    PLAYLIST_NAME=$(basename "$folder")

    # Maintain the index file for playlists
    INDEX_FILE="playlist_index.txt"
    if [ ! -f "$INDEX_FILE" ]; then
        touch "$INDEX_FILE"
    fi

    # Add folder path and playlist to index if not already present
    if ! grep -q "$folder" "$INDEX_FILE"; then
        echo "$folder - $PLAYLIST_NAME" >> "$INDEX_FILE"
    fi

    # Run the Python script as a background process and show progress animation
    python3 youtubedownloader.py "$url" "$folder" "$file" "$is_audio" "$res" &

    PYTHON_PID=$!
    show_progress $PYTHON_PID

    wait $PYTHON_PID
    if [ $? -ne 0 ]; then
        echo "Failed to run the Python script. Aborting."
        deactivate || exit 1
    fi
}

# Create a virtual environment if it doesn't exist
VENV_DIR="venv"
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment in $VENV_DIR"
    python3 -m venv "$VENV_DIR"
    if [ $? -ne 0 ]; then
        echo "Failed to create virtual environment. Aborting."
        exit 1
    fi
fi

# Verify the virtual environment
if [ -f "$VENV_DIR/bin/activate" ]; then
    echo "Virtual environment created successfully."
else
    echo "Failed to find virtual environment activation script. Aborting."
    exit 1
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"
if [ $? -ne 0 ]; then
    echo "Failed to activate virtual environment. Aborting."
    exit 1
fi

# Install required packages from requirements.txt
pip3 install -r requirements.txt
if [ $? -ne 0 ]; then
    echo "Failed to install required packages. Aborting."
    deactivate || exit 1
fi

# Parse parameters with support for short flags
while [ "$1" != "" ]; do
    case $1 in
        -u | --url ) shift
                     URL=$1
                     ;;
        -f | --filename ) shift
                          FILENAME=$1
                          ;;
        -p | --folderPath ) shift
                            FOLDERPATH=$1
                            ;;
        -r | --resolution ) shift
                            RESOLUTION=$1
                            ;;
        * ) echo "Invalid parameter: $1"
            deactivate || exit 1
    esac
    shift
done

# Determine if the file is audio or video based on the filename extension
if [[ "$FILENAME" == *.mp3 ]]; then
    ISAUDIO="true"
    RESOLUTION="none"
else
    ISAUDIO="false"
fi

# Print parsed parameters for debugging
echo "URL: $URL"
echo "Filename: $FILENAME"
echo "Folder Path: $FOLDERPATH"
echo "Resolution: $RESOLUTION"
echo "Is Audio Only: $ISAUDIO"

# Ensure the folder path exists
if [ ! -d "$FOLDERPATH" ]; then
    mkdir -p "$FOLDERPATH"
fi

# Get the playlist name based on the folder path
PLAYLIST_NAME=$(basename "$FOLDERPATH")

# Maintain the index file for playlists
INDEX_FILE="playlist_index.txt"
if [ ! -f "$INDEX_FILE" ]; then
    touch "$INDEX_FILE"
fi

# Add folder path and playlist to index if not already present
if ! grep -q "$FOLDERPATH" "$INDEX_FILE"; then
    echo "$FOLDERPATH - $PLAYLIST_NAME" >> "$INDEX_FILE"
fi

# Run the Python script as a background process and show progress animation
python3 youtubedownloader.py "$URL" "$FOLDERPATH" "$FILENAME" "$ISAUDIO" "$RESOLUTION" &

PYTHON_PID=$!
show_progress $PYTHON_PID

wait $PYTHON_PID
if [ $? -ne 0 ]; then
    echo "Failed to run the Python script. Aborting."
    deactivate || exit 1
fi

# Deactivate virtual environment
deactivate
