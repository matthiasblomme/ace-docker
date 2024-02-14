#!/bin/bash

barFile=$1
#fail if $1 is not supplied
if [ -z "$barFile" ]; then echo "no bar file specified";exit 1; fi

#fail if $barFile does not exist
if [ ! -f "$barFile" ]; then echo "$barFile does not exist";exit 1; fi

# Step 1: Create a temporary directory to hold the items
mkdir temp_dir

# Extract only the desired items to the temporary directory
unzip $barFile "META-INF/*" -d temp_dir
unzip $barFile "${BUILD_PROJECT_NAME}.*" -d temp_dir

# Step 2: Remove all items from the original zip file
zip -d $barFile "*"

# Step 3: Add back the kept items from the temporary directory to the zip file
cd temp_dir
zip -ur $barFile "META-INF"
# Explicitly list and add files matching the pattern to the zip
# This loop handles each matching file individually
for file in ${BUILD_PROJECT_NAME}.*; do
    if [ -e "$file" ]; then
        zip -ur $barFile "$file"
    else
        echo "No files found matching ${BUILD_PROJECT_NAME}.*"
    fi
done

# Cleanup: Remove the temporary directory
cd ..
rm -rf temp_dir