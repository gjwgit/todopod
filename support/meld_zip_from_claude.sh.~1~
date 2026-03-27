#!/bin/bash

# Check if a filename was provided

if [ $# -ne 0 ]; then
    echo "Usage: $0"
    exit 1
fi

# Find the latest zip file to run meld across.

FIND_CLAUDE=$(find ~/Downloads -name "rolopod_lib*.zip" 2>/dev/null | head -1)
echo "Found ${FIND_CLAUDE}"

if [ -z "$FIND_CLAUDE" ]; then
    echo "Error: can not find the Claude zip file in Downloads"
    exit 1
fi

# Create a temporary folder to work in

mkdir tmp

# Extract the zip file.

(cd tmp; unzip "${FIND_CLAUDE}")

# Run meld with the file and find result

meld tmp/lib lib

# Remove the file after meld closes

rm -rf tmp
rm -i "${FIND_CLAUDE}"
