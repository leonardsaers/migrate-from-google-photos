# Migrate or localy store your photos from Google Photos

Google allows you to export all files from Google Photos using the Takeout self-service tool:

[Google Takeout](https://takeout.google.com/)

The Takeout tool makes it possible to create a local backup of all your photos or migrate to another photo service.


The self-service is accessible and easy to use for downloading all your photos, but there are a few extra steps needed after you download all your content from Google Photos.


You can go through the following steps to take out your photos and videos:

1. Use the self-service to request a takeout of all the content within Google Photos.
2. Google will prepare several zip files for you to download, containing all your content within the Google Photos service. Download all takeout files to an empty folder.
3. Use the shell script [process_google_takeout.sh](process_google_takeout.sh), and provide the path to the folder used for Google takeout files as an argument.

``` sh
sh process_google_takeout.sh /home/abc/takeout/
```

The shell script unzips all the takeout files into one single folder and then uses the Node.js-based open-source tool [Google Photo Migrate](https://github.com/garzj/google-photos-migrate) to add metadata to images and videos.


## Prerequisites

Visit [Google Photos Migrate](https://github.com/garzj/google-photos-migrate) and read their prerequisites.

## Disclaimer

This script and instruction are provided "as is" without any warranties. The user is responsible for backing up all data before running the script. The creator of this script is not liable for any data loss or damages that may occur from using the script. Use at your own risk.


