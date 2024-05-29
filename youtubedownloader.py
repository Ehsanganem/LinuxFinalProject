from pytube import YouTube
from pytube.exceptions import PytubeError
import sys
import os

if len(sys.argv) != 6:
    print("Usage: youtubedownloader.py <url> <folderpath> <filename> <isaudio> <resolution>")
    sys.exit(1)

url, folderpath, filename, is_audio_only, resolution = sys.argv[1:6]

try:
    # Create a YouTube object
    yt = YouTube(url)
except PytubeError as e:
    print(f"Failed to fetch video: {e}")
else:
    try:
        # video or audio
        if is_audio_only.lower() == 'true':
            # Filter to audio streams
            stream = yt.streams.filter(only_audio=True).first()
        else:
            # Filter video stream with all filters values, select the first match
            stream = yt.streams.filter(res=resolution, file_extension='mp4').first()

        # Check if a valid stream is available
        if stream:
            # Ensure the folder path exists
            if not os.path.exists(folderpath):
                os.makedirs(folderpath)
            # Download the stream to local system
            output_path = stream.download(output_path=folderpath, filename=filename)
            print(f"Downloaded finish")
        else:
            print("Resolution availability error.")
    except PytubeError as e:
        print(f"Download failed: {e}")
