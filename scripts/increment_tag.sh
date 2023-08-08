#!/bin/bash

# Get the target directory from command-line argument
target_dir="$1"

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
latest_tag=$(git describe --tags "$(git rev-list --tags --max-count=1)")

echo "Found tag $latest_tag"

# If there are no tags, create the initial tag with v1.0.0 format
if [ -z "$latest_tag" ]; then
    latest_tag="v1.0.0"
else
    # If tags exist, parse the version part
    tag_prefix=$(echo "$latest_tag" | sed -n 's/\(.*\)\([0-9]\+\.[0-9]\+\.[0-9]\+\)/\1/p')
    version=$(echo "$latest_tag" | sed -n 's/\(.*\)\([0-9]\+\.[0-9]\+\.[0-9]\+\)/\2/p')


    if [ -z "$version" ]; then
        echo "Error: Could not extract version from the latest tag '$latest_tag'."
        exit 1
    fi

    # Increment the fix part of the version
    IFS='.' read -r major minor fix <<< "$version"
    ((fix++))
    latest_tag="$tag_prefix$major.$minor.$fix"
fi

# Write the major.minor.fix part of the tag to tag.txt in ./artifact directory
echo "$latest_tag" > "$current_dir/artifact/tag.txt"
echo "Creating new tag $latest_tag"
# Set and push the latest tag
git tag "$latest_tag"
git push origin --tags
# Change back to the original directory
cd "$current_dir" || exit 1