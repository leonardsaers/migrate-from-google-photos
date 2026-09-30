#!/bin/bash

# Script to extract duplicate photos between Photos/Timeline and Archive/Google-Photos
# using extract-duplicates.xslt on photos.xml

# Check if xsltproc is installed
if ! command -v xsltproc &> /dev/null; then
    echo "xsltproc is not installed. Please install xsltproc first (e.g. sudo dnf install libxslt)."
    exit 1
fi

XML_FILE="photos.xml"
XSLT_FILE="extract-duplicates.xslt"
OUTPUT_FILE="${1:-duplicates.txt}"

# Check if XML file exists
if [ ! -f "$XML_FILE" ]; then
    echo "XML file $XML_FILE not found. Please run extract_file_structure_from_jotta.sh first."
    exit 1
fi

# Check if XSLT file exists
if [ ! -f "$XSLT_FILE" ]; then
    echo "XSLT file $XSLT_FILE not found."
    exit 1
fi

echo "Extracting duplicates from $XML_FILE using $XSLT_FILE..."

# Run XSLT transformation
if xsltproc "$XSLT_FILE" "$XML_FILE" > "$OUTPUT_FILE"; then
    COUNT=$(wc -l < "$OUTPUT_FILE" | tr -d ' ')
    if [ "$COUNT" -gt 0 ]; then
        echo "Found $COUNT duplicates saved to $OUTPUT_FILE"
    else
        echo "No duplicates found."
    fi
else
    echo "Error: Failed to process $XML_FILE with $XSLT_FILE"
    exit 1
fi
