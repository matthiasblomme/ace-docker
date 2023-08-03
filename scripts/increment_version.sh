#!/bin/bash
version_file="$1"

# Read the JSON response from version.txt and extract the value of "version" field
version=$(grep -o '"version": "[^"]*' "$version_file" | cut -d'"' -f4)

# Function to increment the "fix" part of the version (e.g., 1.0.0 -> 1.0.1)
increment_version_fix() {
    local version="$1"
    local major
    local minor
    local fix

    IFS='.' read -r major minor fix <<< "$version"
    ((fix++))
    echo "$major.$minor.$fix"
}

# Check if the version is not found (resource doesn't exist)
if [ -z "$version" ]; then
    # Set the new version to "1.0.0"
    incremented_version="1.0.0"
else
    # Increment the "fix" part of the version
    incremented_version=$(increment_version_fix "$version")
fi

# Print the incremented version
echo "$incremented_version"
