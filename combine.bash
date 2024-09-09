#!/bin/bash

PREFIX_TO_REMOVE=$1     # This part of name of .cbz files will be removed in final directory names
OUT_ARCHIVE_NAME=$2     # Final archive name
WORKING_DIR="${3:-.}"   # working directory

function usage {
    echo "combine.bash - simple zip archive merger, that is made to combine multiple .cbz files into one big one"
    echo "Usage: ./combine.bash <prefix-to-remove> <out-archive-name> [working-directory]"
    exit 0
}

# Prefix and out-archive name are mandatory
if (( $# < 2 )); then
    usage
fi

# .cbz is just a renamed .zip, so we also need zip utilities
if ! command -v zip &> /dev/null
then
    echo "zip could not be found"
    exit 1
fi

cbzs=$(find "$WORKING_DIR" -type f -name "*.cbz" | wc -l)
if [ "$cbzs" -lt 2 ]; then
    echo "No work to be done"
    exit
fi

# Create directory for final archive
mkdir -p "$WORKING_DIR/$OUT_ARCHIVE_NAME"

echo "Packing .cbz files..."

for file in "$WORKING_DIR"/*.cbz; do
    # Get basename of archive
    filename=$(basename -- "$file")
    echo -n "$filename... "
    # Unzip .cbz archive
    unzip "$file" &> /dev/null
    # Remove its extension
    filename="${filename%.cbz}"
    # Remove the unwanted prefix
    out_dirname="${filename//$PREFIX_TO_REMOVE}"
    # Move unziped directory into final archive directory with updated name
    mv "$filename" "$WORKING_DIR/$OUT_ARCHIVE_NAME/$out_dirname"
    echo "Done"
done

echo -n "Creating final archive..." 
# re-zip final archive into .cbz
zip -r "$WORKING_DIR/$OUT_ARCHIVE_NAME.cbz" "$WORKING_DIR/$OUT_ARCHIVE_NAME" &> /dev/null
echo "Done"
# cleanup
rm -rf "$WORKING_DIR/$OUT_ARCHIVE_NAME"
echo "Finished"
