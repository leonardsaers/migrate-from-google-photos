#!/bin/bash

# Script to remove duplicate files from Jottacloud using rclone
# Usage: sh remove_duplicates.sh <path_to_duplicates_txt> [--remote <remote_name>] [--dry-run]
# Example: sh remove_duplicates.sh duplicates.txt --remote jotta --dry-run

set -euo pipefail

# Default remote name
REMOTE_NAME="jottacloud"

# Parse arguments
DUPLICATES_TXT=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --remote)
            REMOTE_NAME="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            if [ -z "$DUPLICATES_TXT" ]; then
                DUPLICATES_TXT="$1"
                shift
            else
                echo "❌ Error: Unknown argument: $1"
                echo "Usage: $0 <path_to_duplicates_txt> [--remote <remote_name>] [--dry-run]"
                exit 1
            fi
            ;;
    esac
done

# Check if duplicates.txt path is provided
if [ -z "$DUPLICATES_TXT" ]; then
    echo "Usage: $0 <path_to_duplicates_txt> [--remote <remote_name>] [--dry-run]"
    echo "Example: $0 duplicates.txt --remote jotta --dry-run"
    exit 1
fi

# Show dry-run mode if enabled
if [ "$DRY_RUN" = true ]; then
    echo "🔹 DRY RUN MODE: No files will be deleted. Showing what would be done."
fi

# Check if duplicates.txt exists
if [ ! -f "$DUPLICATES_TXT" ]; then
    echo "❌ Error: File '$DUPLICATES_TXT' not found."
    exit 1
fi

# Check if rclone is installed
if ! command -v rclone &> /dev/null; then
    echo "❌ Error: rclone is not installed. Please install it first."
    echo "Installation: https://rclone.org/install/"
    exit 1
fi

# Check if rclone is configured for the specified remote
if ! rclone listremotes | grep -q "$REMOTE_NAME"; then
    echo "❌ Error: No rclone remote named '$REMOTE_NAME' found."
    echo "Please configure rclone for Jottacloud first."
    echo "Example: rclone config"
    exit 1
fi

# Verify connection to the remote by listing the root directory
echo "🔍 Verifying connection to remote '$REMOTE_NAME'..."
if ! rclone ls "${REMOTE_NAME}:" --max-depth 0 --quiet 2>/dev/null; then
    echo "❌ Error: Failed to connect to remote '$REMOTE_NAME'."
    echo "Please check your rclone configuration and network connection."
    exit 1
fi
echo "✅ Connection to remote '$REMOTE_NAME' verified."

# Log files
LOG_FILE="removed_duplicates_$(date +%Y%m%d_%H%M%S).log"
ERROR_LOG="failed_to_remove_$(date +%Y%m%d_%H%M%S).log"

# Clear log files
> "$LOG_FILE"
> "$ERROR_LOG"

echo "📄 Reading duplicates from: $DUPLICATES_TXT"
echo "🗑️  Log file: $LOG_FILE"
echo "❌ Error log: $ERROR_LOG"
echo ""

# Count total files to process
TOTAL_FILES=$(wc -l < "$DUPLICATES_TXT" | tr -d ' ')
echo "📊 Found $TOTAL_FILES duplicate files to process."
echo ""

# Process each file in duplicates.txt
SUCCESS_COUNT=0
FAIL_COUNT=0

while IFS= read -r file_path; do
    # Skip empty lines
    if [ -z "$file_path" ]; then
        continue
    fi

    # Trim leading/trailing whitespace
    file_path=$(echo "$file_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Skip if empty after trimming
    if [ -z "$file_path" ]; then
        continue
    fi

    # Remove leading '/archive' from the path (since rclone for Jottacloud defaults to Archive/)
    # Example: /archive/Google-Photos/2021/12/IMG.jpg -> Google-Photos/2021/12/IMG.jpg
    file_path=$(echo "$file_path" | sed 's|^/archive/||')

    # Construct the full remote path for rclone
    # Using the specified remote name and the cleaned path
    REMOTE_PATH="${REMOTE_NAME}:$file_path"
    
    # Use rclone to delete the file
    if [ "$DRY_RUN" = true ]; then
        echo "$REMOTE_PATH" >> "$LOG_FILE"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        if rclone delete "$REMOTE_PATH" --quiet 2>> "$ERROR_LOG"; then
            echo "$REMOTE_PATH" >> "$LOG_FILE"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            echo "$REMOTE_PATH - Reason: $(tail -n 1 "$ERROR_LOG")" >> "$ERROR_LOG"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
        
        # Add a small delay to avoid rate limiting by the API
        sleep 0.5
    fi
    
    # Print progress on the same line using \r (carriage return)
    CURRENT_TOTAL=$((SUCCESS_COUNT + FAIL_COUNT))
    printf "\rProcessing files: %d / %d" "$CURRENT_TOTAL" "$TOTAL_FILES"

done < "$DUPLICATES_TXT"

echo ""
echo "----------------------------------------"
echo "✅ Successfully processed: $SUCCESS_COUNT"
echo "❌ Failed to process: $FAIL_COUNT"
echo "----------------------------------------"

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo ""
    echo "⚠️  Some files failed to delete. Check $ERROR_LOG for details."
fi

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "🔹 DRY RUN COMPLETE: No files were actually deleted."
    echo "   To delete the files, run the script without --dry-run."
fi

echo ""
echo "📝 Log files saved:"
echo "   - $LOG_FILE"
echo "   - $ERROR_LOG"