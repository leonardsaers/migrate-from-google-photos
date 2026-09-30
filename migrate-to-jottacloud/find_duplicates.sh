#!/bin/bash

# Skript för att hitta dubletter baserat på filnamn med hjälp av jq


# Kontrollera att jq är installerat
if ! command -v jq &> /dev/null; then
    echo "jq är inte installerat. Installera jq först."
    exit 1
fi

# Kontrollera att jotta-cli är installerat
if ! command -v jotta-cli &> /dev/null; then
    echo "jotta-cli är inte installerat. Installera jotta-cli först."
    exit 1
fi

# Mappen att söka i
TARGET_DIR="Photos/Timeline/2026/5"

# Fil för att spara dubletter
OUTPUT_FILE="duplicates.txt"

# Hämta filinformation från jotta-cli och bearbeta med jq
jotta-cli ls -laj "$TARGET_DIR" | jq -r '.Files | group_by(.Name) | map(select(length > 1)) | flatten | .[] | .Path' > "$OUTPUT_FILE"

# Kontrollera om det finns några dubletter
if [ -s "$OUTPUT_FILE" ]; then
    echo "Dubletter hittades och har sparats till $OUTPUT_FILE"
    cat "$OUTPUT_FILE"
else
    echo "Inga dubletter hittades."
fi
