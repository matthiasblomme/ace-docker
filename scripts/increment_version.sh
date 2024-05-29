#!/bin/bash

# This script retrieves the current version from a JSON file and increments the patch version.
# If there is an error or no version is found, it defaults to version 1.0.0.
# The incremented version is output for further use.

# Path to the file containing the JSON response with the version information
version_file="$1"

# Read the JSON response from the provided file and extract the value of the "version" field
version=$(grep -o '"version": "[^"]*' "$version_file" | cut -d'"' -f4)

# Function to increment the "fix" part of the version (e.g., 1.0.0 -> 1.0.1)
increment_version_fix() {
    local version="$1"
    local major
    local minor
    local fix

    # Split the version string into major, minor, and fix components
    IFS='.' read -r major minor fix <<< "$version"
    # Increment the "fix" part
    ((fix++))
    # Return the new version string
    echo "$major.$minor.$fix"
}

# Check if the version is not found (resource doesn't exist)
if [ -z "$version" ]; then
    # Set the new version to "1.0.0" if no version is found
    incremented_version="1.0.0"
else
    # Increment the "fix" part of the version
    incremented_version=$(increment_version_fix "$version")
fi

# Print the incremented version
echo "$incremented_version"
