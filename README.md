YouTube Media Downloader
Overview
This project provides a comprehensive script-based solution for downloading and managing YouTube media files.
It includes functionalities for downloading both audio and video files, creating playlists, 
and managing them through the command line. Additionally, the project supports playing media directly from the terminal using the mpv player.

Features
Media Downloading: Download videos and audio from YouTube in various resolutions and formats.
Playlist Management: Automatically organize downloaded media into playlists based on specified folders.
Playlist Playback: Play created playlists using mpv directly from the terminal.
Virtual Environment Setup: Automatically sets up a Python virtual environment and installs required dependencies.
Progress Animation: Displays a progress animation while media files are being downloaded.
Multiple Playlist Support: Supports merging and playing multiple playlists together.
Parameter Validation: Checks for required parameters and tools, providing informative error messages.
Scripts
youtubedownloader.sh: The main script for handling media downloading, playlist management, and playback.
youtubedownloader.py: The Python script used for downloading media from YouTube using the pytube library.
Usage
Downloading Media
To download a video or audio file:

bash
Copy code
./youtubedownloader.sh --url "https://www.youtube.com/watch?v=example" --filename "video.mp4" --folderPath "./Media" --resolution "720p"
Listing Playlists
To list all available playlists:

bash
Copy code
./youtubedownloader.sh --list
To list specific playlists:

bash
Copy code
./youtubedownloader.sh --list "Playlist1" "Playlist2"
Playing Playlists
To play a playlist:

bash
Copy code
./youtubedownloader.sh --play "Playlist1"
To play multiple playlists:

bash
Copy code
./youtubedownloader.sh --play "Playlist1" "Playlist2"
Requirements
Python 3
pytube library
mpv player
jq (for JSON parsing)
Setup
Install Required Tools:

bash
Copy code
sudo apt update
sudo apt install python3 python3-pip mpv jq
Run the Script:

bash
Copy code
./youtubedownloader.sh [options]
Contributions
Contributions are welcome! Please fork the repository and submit a pull request for any improvements or additional features.

License
This project is licensed under the MIT License - see the LICENSE file for details.

Author
Ehsan Ganem

