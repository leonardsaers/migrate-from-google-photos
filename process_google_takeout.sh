#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_zip_files>"
    exit 1
fi

# Path to the directory containing ZIP files, passed as an argument
ZIP_FILES_PATH="$1"

# Common directory to extract all ZIP files
EXTRACT_DIR="$ZIP_FILES_PATH/extracted"
TAKEOUT_DIR="$EXTRACT_DIR/Takeout"

# Output and error directories
OUTPUT_PATH="$ZIP_FILES_PATH/output"
ERROR_PATH="$ZIP_FILES_PATH/error"

# Create directories if they do not already exist
mkdir -p "$EXTRACT_DIR"
mkdir -p "$OUTPUT_PATH"
mkdir -p "$ERROR_PATH"

# Log file for overwritten files
OVERWRITE_LOG="$ZIP_FILES_PATH/overwrite_log.txt"

# Clear the log file if it already exists
> "$OVERWRITE_LOG"

# Iterate over all ZIP files in the directory
for zip_file in "$ZIP_FILES_PATH"/*.zip; do
  # Check if there are any ZIP files
  if [ -e "$zip_file" ]; then
    # Unzip the ZIP file into the common directory and log overwritten files
    unzip -o -q "$zip_file" -d "$EXTRACT_DIR" | grep -i "replace" >> "$OVERWRITE_LOG"

    echo "Unzipped $zip_file to $EXTRACT_DIR."
  else
    echo "No ZIP files found in the directory."
  fi
done

# Check if any files were overwritten
if [ -s "$OVERWRITE_LOG" ]; then
    echo "Warning: Some files were overwritten during extraction. See $OVERWRITE_LOG for details."
else
    echo "No files were overwritten during extraction."
fi

# Run google-photos-migrate on the common extracted directory
npx google-photos-migrate@latest full "$TAKEOUT_DIR" "$OUTPUT_PATH" "$ERROR_PATH" --verbose --timeout 60000

echo "Processing of all ZIP files completed."

