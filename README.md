# Migrate or localy store your photos from Google Photos

Google allows you to export all files from Google Photos using the Takeout self-service tool:

[Google Takeout](https://takeout.google.com/)

The Takeout tool makes it possible to create a local backup of all your photos or migrate to another photo service.


The self-service is accessible and easy to use for downloading all your photos, but there are a few extra steps needed after you download all your content from Google Photos.


You can go through the following steps to take out your photos and videos:

1. Use the self-service to request a takeout of all the content within Google Photos.
2. Google will prepare several zip files for you to download, containing all your content within the Google Photos service. Download all takeout files to the [takeout](./takeout/) inside this project's directory. **Note:** It is important that *all* zip files from the export are placed in this folder before proceeding, as Google randomly distributes photos and their associated metadata (JSON files) across different zip files.
3. Use the shell script `process_google_takeout.sh`, and provide the path to the `takeout` folder as an argument.

```sh
sh process_google_takeout.sh ./takeout/
```

The shell script unzips all the takeout files into one single folder and then uses the Node.js-based open-source tool [Google Photo Migrate](https://github.com/garzj/google-photos-migrate) to add metadata to images and videos.

### Note on Errors and Unsupported Files

During the migration of metadata, some files might be placed in the `error` folder created by the script. This typically happens for:

- **Live Photos / Motion Photos (`.MP`, `.MP4`):** When capturing a Live Photo, modern smartphones generate both a still image and a short video clip. Google Takeout usually only provides a metadata JSON file for the still image (`.jpg`), leaving the accompanying video file without one.
- **Edited or Duplicated Images (`-edited.jpg`, `(1).jpg`, `~2.jpg`):** If an image has been cropped or filtered within Google Photos, Google exports both the original and the edited version. Often, only the original image receives a JSON file, causing the edited versions to fail the metadata match.

Files that end up in the `error` folder will **not** be assigned corrected metadata and will **not** be included in the final upload to Jottacloud by the migration script. The original still images for these files are typically successfully processed and placed in the `output` folder.

## Prerequisites

Visit [Google Photos Migrate](https://github.com/garzj/google-photos-migrate) and read their prerequisites.

# Migrate to Jotta cloud

This next part will let you migrate to [Jotta Cloud](https://jottacloud.com/)

## Preparation

1. Set up your account on jotta cloud
2. Search the website for jotta cloud for the "command line tool" instructions and setup the command line tool.
3. Follow the jotta cloud instruction for logging in to the command line tool.

## Migrate to Jotta

Use the shell script `migrate_to_jotta.sh` to migrate all files to jotta.

```sh
sh migrate_to_jotta.sh
```

### The file structure

All files will be uploaded to your jotta Archive in a folder called 'Google-Photos' and then separated in a year and mounth structure.

```text
Archive/
 └── Google-Photos/
     ├── 2021/
     │   ├── 11/
     │   └── 12/
     │       ├── IMG_20211231_102630_222.jpg
     │       └── PXL_20211231_183300326.mp4
     └── 2022/
         └── 01/
             └── PXL_20220101_115300076.jpg
```


# Disclaimer

This script and instruction are provided "as is" without any warranties. The user is responsible for backing up all data before running the script. The creator of this script is not liable for any data loss or damages that may occur from using the script. Use at your own risk.

