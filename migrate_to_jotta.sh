#!/bin/bash

# Configuration
SOURCE_DIR="./takeout/output/Photos"
JOTTA_REMOTE="Google-Photos"

# Function to get creation year and month from EXIF data using exiftool
get_date_info() {
    local file="$1"
    # Try to extract the CreateDate using exiftool
    local date_str=$(exiftool -s3 -CreateDate "$file" 2>/dev/null)

    # If CreateDate is not found, try to use FileModifyDate as a fallback
    if [ -z "$date_str" ]; then
        date_str=$(exiftool -s3 -FileModifyDate "$file" 2>/dev/null)
    fi
    
    # Check if a date string was retrieved and format it
    if [ -n "$date_str" ]; then
        # Format is typically "YYYY:MM:DD HH:MM:SS" or similar, extract Year and Month
        local year=$(echo "$date_str" | awk -F: '{print $1}' | tr -d ' ')
        local month=$(echo "$date_str" | awk -F: '{print $2}')
        
        # Ensure year and month are valid numbers
        if [[ "$year" =~ ^[0-9]{4}$ ]] && [[ "$month" =~ ^[0-9]{2}$ ]]; then
            echo "$year/$month"
            return 0
        fi
    fi
    
    # Return "Unknown" if no valid date could be parsed
    echo "Unknown"
    return 1
}

echo "Starting Jotta migration for all files in $SOURCE_DIR..."

# Calculate total number of files to process
TOTAL_FILES=$(find "$SOURCE_DIR" -type f | wc -l)
echo "Found $TOTAL_FILES files to process."

SUCCESS_COUNT=0
FAIL_COUNT=0
FAIL_LOG="failed_jotta_uploads.log"

# Clear previous log file
> "$FAIL_LOG"

# Loop through all files in the source directory
while IFS= read -r -d $'\0' file; do
    # Skip if it's not a regular file
    if [ ! -f "$file" ]; then
        continue
    fi
    
    FILE_NAME=$(basename "$file")
    
    # Determine the year/month structure for the file
    if ! DATE_PATH=$(get_date_info "$file"); then
        echo "$file - Reason: Could not extract valid date" >> "$FAIL_LOG"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    else
        # Construct the remote path in Jottacloud
        REMOTE_PATH="$JOTTA_REMOTE/$DATE_PATH/$FILE_NAME"
        
        # Upload the single file to Jotta in the background (using --nogui)
        if jotta-cli archive "$file" --remote="$REMOTE_PATH" --nogui > /dev/null 2>&1; then
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            echo "$file - Reason: jotta-cli command failed" >> "$FAIL_LOG"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    fi
    
    CURRENT_TOTAL=$((SUCCESS_COUNT + FAIL_COUNT))
    
    # Print progress on the same line using \r (carriage return)
    printf "\rProcessing files: %d / %d" "$CURRENT_TOTAL" "$TOTAL_FILES"

done < <(find "$SOURCE_DIR" -type f -print0)

echo ""
echo "Migration queueing completed!"
echo "----------------------------------------"
echo "Successfully queued for upload: $SUCCESS_COUNT"
echo "Failed to queue: $FAIL_COUNT"

if [ $FAIL_COUNT -gt 0 ]; then
    echo "----------------------------------------"
    echo "The following files failed to queue:"
    cat "$FAIL_LOG"
    echo ""
    echo "A detailed list has been saved to $FAIL_LOG in this directory."
fi

echo "----------------------------------------"
