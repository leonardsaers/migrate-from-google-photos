#!/bin/bash

# Script to extract file structure from Jotta and generate XML file

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install jq first."
    exit 1
fi

# Check if jotta-cli is installed
if ! command -v jotta-cli &> /dev/null; then
    echo "jotta-cli is not installed. Please install jotta-cli first."
    exit 1
fi

# Check if xmllint is installed
if ! command -v xmllint &> /dev/null; then
    echo "xmllint is not installed. Please install xmllint first."
    exit 1
fi

# Directory to search in
TIMELINE_DIR="Photos/Timeline"
GOOGLE_PHOTOS_DIR="Archive/Google-Photos"

# File to save XML
OUTPUT_FILE="photos.xml"

# DTD file
DTD_FILE="photos.dtd"

# Create XML file with DTD
XML_HEADER="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"photos.xsl\"?>
<!DOCTYPE jottacloud SYSTEM \"photos.dtd\">
<jottacloud>"

# Write XML header to file
echo "$XML_HEADER" > "$OUTPUT_FILE"

# Function to add photos from a directory
add_photos() {
    local dir="$1"

    # Get all years from the directory
    local years=$(jotta-cli ls -j "$dir" 2>/dev/null | jq -r '.Folders[]?.Name' 2>/dev/null)

    if [ -z "$years" ]; then
        echo "No years found in directory $dir"
        return
    fi

    echo "$years" | while read -r year; do
        [ -z "$year" ] && continue

        # Add year to XML file
        echo "    <year value=\"$year\">" >> "$OUTPUT_FILE"

        # Get all months for the year
        local months=$(jotta-cli ls -j "$dir/$year" 2>/dev/null | jq -r '.Folders[]?.Name' 2>/dev/null)

        if [ -z "$months" ]; then
            echo "No months found for year $year"
            echo "    </year>" >> "$OUTPUT_FILE"
            continue
        fi

        echo "$months" | while read -r month; do
            [ -z "$month" ] && continue

            # Remove leading zero if month starts with 0
            local month_val="${month#0}"

            # Add month to XML file
            echo "      <month value=\"$month_val\">" >> "$OUTPUT_FILE"

            # Get all files for the month
            local files=$(jotta-cli ls -laj "$dir/$year/$month" 2>/dev/null | jq -r '.Files[]? | "        <file name=\"" + (.Name | @html) + "\" path=\"" + (.Path | @html) + "\"/>"' 2>/dev/null)

            if [ -z "$files" ]; then
                echo "No files found for month $month"
            else
                echo "$files" >> "$OUTPUT_FILE"
            fi

            echo "      </month>" >> "$OUTPUT_FILE"
        done

        echo "    </year>" >> "$OUTPUT_FILE"
    done
}

# Add photos from Photos/Timeline
echo "  <photos>" >> "$OUTPUT_FILE"
add_photos "$TIMELINE_DIR"
echo "  </photos>" >> "$OUTPUT_FILE"

# Add photos from Archive/Google-Photos
echo "  <google-photos>" >> "$OUTPUT_FILE"
add_photos "$GOOGLE_PHOTOS_DIR"
echo "  </google-photos>" >> "$OUTPUT_FILE"

# Write XML footer to file
echo "</jottacloud>" >> "$OUTPUT_FILE"

# Validate XML file with xmllint
if xmllint --noout --valid "$OUTPUT_FILE"; then
    echo "XML file has been created and validated successfully: $OUTPUT_FILE"
else
    echo "XML file has been created but validation failed. See error messages above."
    exit 1
fi

