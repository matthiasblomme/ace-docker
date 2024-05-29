#!/bin/bash

# This script retrieves the latest tag from a Git repository and increments its version number.
# Depending on the branch type (feature or fix), it increments either the minor or the patch version.
# The new version is written to a file and the repository is tagged with the new version.

# Get the target directory from command-line argument
target_dir="$1"
branch="$2"

# Check if the target directory exists
if [ ! -d "$target_dir" ]; then
    echo "Error: Target directory '$target_dir' does not exist."
    exit 1
fi

# Save the current working directory
current_dir=$(pwd)

# Change to the target directory
cd "$target_dir" || exit 1

# List the latest git tag
latest_tag=$(git describe --tags --abbrev=0 $(git rev-list --tags --max-count=1))
echo "Found tag $latest_tag"

# Define the tag prefix
tag_prefix="$BUILD_PROJECT_NAME-v"

# If there are no tags, create the initial tag with v1.0.0 format
if [ -z "$latest_tag" ]; then
    version="1.0.0"
    IFS='.' read -r major minor fix <<< "$version"
else
    # If tags exist, parse the version part
    tag_prefix=$(echo "$latest_tag" | sed -n 's/\(.*\)\([0-9]\+\.[0-9]\+\.[0-9]\+\)/\1/p')
    version=$(echo "$latest_tag" | sed -n 's/\(.*\)\([0-9]\+\.[0-9]\+\.[0-9]\+\)/\2/p')

    # Check if the version could be extracted
    if [ -z "$version" ]; then
        echo "Error: Could not extract version from the latest tag '$latest_tag'."
        exit 1
    fi

    # Assign the BUILD_PROJECT_NAME to the tag prefix if it is empty or just 'v'
    if [ -z "$tag_prefix" ] || [ "$tag_prefix" = "v" ]; then
        tag_prefix="$BUILD_PROJECT_NAME-v"
    fi

    # Split the version into major, minor, and fix parts
    IFS='.' read -r major minor fix <<< "$version"

    # Increment minor version for feature branches
    if [[ "$branch" =~ features\/ ]]; then
        ((minor++))
        fix=0
    # Increment fix version for fix branches
    elif [[ "$branch" =~ fix\/ ]]; then
        ((fix++))
    else
        echo "Error: Unsupported branch '$branch'. Please use features/* or fix/*"
        exit 1
    fi
fi

# Form the latest tag
latest_tag="$tag_prefix$major.$minor.$fix"

# Write the major.minor.fix part of the tag to tag.txt in ./artifact directory
echo "$major.$minor.$fix" > "$current_dir/artifact/tag.txt"
echo "Creating new tag $latest_tag"
# Set and push the latest tag
git tag -a -m "Tag from pipeline build" "$latest_tag"
git push origin --tags

# Change back to the original directory
cd "$current_dir" || exit 1
