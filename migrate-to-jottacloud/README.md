# Migrate to Jottacloud

Instructions on how to migrate your photos and videos to [Jottacloud](https://jottacloud.com/).

While design decisions in Google Photos make it complicated to export your media, Jottacloud also has design that makes it complicated when migrating to JottaCloud. Uploading media is straightforward, but the jotta-cli tool can not handle removal of duplicates.

---

## Prerequisites & Dependencies

Before beginning the migration, ensure you have the required CLI tools installed and configured.

### 1. Jottacloud Account & CLI

1. Create an account on [Jottacloud](https://jottacloud.com/).
2. Download and install the official [Jottacloud Command Line Tool (`jotta-cli`)](https://docs.jottacloud.com/en/articles/1436834-jottacloud-command-line-tool).
3. Log in to your account with `jotta-cli`:
   ```sh
   jotta-cli login
   ```

### 2. Required Tools for Migration

The migration upload script (`migrate_to_jotta.sh`) reads EXIF metadata to organize files chronologically:
- **`exiftool`**: Extracts photo capture dates to create Year/Month directory structures.

### 3. Required Tools for Duplicate Handling (Optional)

If you already use Jottacloud on your mobile phone and had backup enabled while simultaneously backing up to Google Photos, the same media may exist in both Jottacloud **Backup** and your Google Photos export.

To detect and remove duplicates, you will need:
- **`jq`**: JSON processor used during remote structure extraction.
- **`xmllint`**: Validates XML structure against the DTD.
- **`xsltproc`**: Evaluates duplicate matches using an XSL transformation.
- **`rclone`**: Configured for Jottacloud to delete duplicates from the `Archive` folder (since `jotta-cli` currently lacks an archive file deletion command).

#### Package Installation Commands

- **Debian / Ubuntu / Raspberry Pi OS:**
  ```sh
  sudo apt update
  sudo apt install libimage-exiftool-perl jq libxml2-utils xsltproc rclone
  ```

- **Fedora / RHEL / CentOS:**
  ```sh
  sudo dnf install perl-Image-ExifTool jq libxml2 libxslt rclone
  ```

#### Configuring rclone for Jottacloud
Run `rclone config` and create a remote (typically named `jottacloud`) using the Jottacloud storage type with default settings and your credentials.

---

## Step 1: Migrate Photos to Jottacloud

Ensure you have processed your Google Takeout archive first using `process_google_takeout.sh` from the repository root. This ensures metadata is merged and photos are placed in `./takeout/output/Photos`.

Run the upload script:

```sh
sh migrate_to_jotta.sh
```

### What this script does:
1. Scans `./takeout/output/Photos` for all image and video files.
2. Uses `exiftool` to inspect `CreateDate` (falling back to `FileModifyDate`) to determine the photo's year and month.
3. Automatically uploads each file to your Jottacloud **Archive** in the following folder structure:
   ```text
   Archive/
    └── Google-Photos/
        ├── 2021/
        │   └── 12/
        │       ├── IMG_20211231_102630_222.jpg
        │       └── PXL_20211231_183300326.mp4
        └── 2022/
            └── 01/
                └── PXL_20220101_115300076.jpg
   ```
4. Displays live progress and logs any failed uploads to `failed_jotta_uploads.log`.

---

## Understanding Potential Duplicates

If the Jottacloud app is installed on your mobile phone, it automatically uploads photos to a timeline in the virtual **Backup** section:

```text
Backup/
 └── Photos/Timeline/
     └── 2021/
         └── 12/
             └── IMG_20211231_102630_222.jpg
```

When you also upload your historical library from Google Photos into the **Archive** section (`Archive/Google-Photos/...`), identical images will exist in both locations.

To reclaim storage, you can remove the duplicates from the **Archive** section while preserving the mobile timeline backup.

---

## Step 2: Handle Duplicates

Follow these 4 steps to detect and remove duplicate files:

### 1. Extract File Structure from Jottacloud
Scan both `Photos/Timeline` and `Archive/Google-Photos` on Jottacloud to create an index file (`photos.xml`):

```sh
sh extract_file_structure_from_jotta.sh
```
*This produces `photos.xml` and validates it against `photos.dtd`.*

### 2. Extract Duplicate Matches
Run the XSLT processor to find files present in both `Photos/Timeline` and `Archive/Google-Photos`:

```sh
sh extract_duplicates.sh
```
*This queries `photos.xml` using `extract-duplicates.xslt` and outputs the duplicate archive paths to `duplicates.txt`.*

> **Note on Matching Strategy:** Duplicates are matched based on Year, Month, and File Name. If you have distinct photos that share identical file names taken in the exact same month, inspect `duplicates.txt` before proceeding.

### 3. Inspect Duplicates
Review `duplicates.txt` to verify the list of files flagged for deletion:

```sh
head -n 20 duplicates.txt
wc -l duplicates.txt
```

### 4. Remove Duplicates via rclone

#### Test with a Dry Run First:
Always perform a dry run to verify the files that would be deleted without altering your cloud storage:

```sh
sh remove_duplicates.sh duplicates.txt --remote jottacloud --dry-run
```
*(Replace `jottacloud` with the name of your rclone remote if named differently).*

#### Perform the Deletion:
Once verified, run the script without the `--dry-run` flag:

```sh
sh remove_duplicates.sh duplicates.txt --remote jottacloud
```

Progress and results will be saved to:
- `removed_duplicates_<timestamp>.log`: List of successfully deleted files.
- `failed_to_remove_<timestamp>.log`: Any files that encountered errors.

---

## Step 3: Prepare Your Mobile Phone

Google Photos is deeply integrated into Android devices. To prevent ongoing sync conflicts or unintentional re-uploads after migrating to Jottacloud:

### 1. Turn off Backup in Google Photos
1. Open the **Google Photos** app.
2. Tap your profile picture in the top right corner.
3. Select **Photos settings** (the gear icon).
4. Tap **Backup** and toggle the switch to **OFF**.

### 2. Free up Device Space (Optional)
1. In Google Photos, tap your profile picture.
2. Select **Free up space on this device**.
3. Confirm deletion of local copies that are already securely stored in the cloud.

### 3. Disable the App (To Silence Persistent Alerts)
On Pixel and other Android devices, the system will regularly prompt you with notifications to re-enable Google Photos backup. You can disable the app:
1. Open phone **Settings**.
2. Navigate to **Apps** > **See all apps**.
3. Select **Photos** (Google Photos).
4. Tap **Disable** and confirm.

> **Note on Android Lock-in:** On some devices (such as Google Pixel phones), changing system wallpaper or specific lock screen shortcuts may link exclusively to the Google Photos app picker. If needed, keep Google Photos enabled with backup permanently toggled off.

---

## Disclaimer

These scripts and instructions are provided "as is" without warranty of any kind. Users are strongly advised to verify backups before deleting any data. The author assumes no liability for data loss or damages resulting from the use of these tools. Use at your own risk.
