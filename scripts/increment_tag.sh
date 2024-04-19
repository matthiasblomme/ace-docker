#!/bin/bash

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
latest_tag=$(git describe --tags --abbrev=0)

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


    IFS='.' read -r major minor fix <<< "$version"

    # increment minor version for feature branches
    if [[ "$branch" =~ features\/ ]]; then
      ((minor++))
      fix=0
    # increment fix version for fix branches
    elif [[ "$branch" =~ fix\/ ]]; then
      ((fix++))
    else
      echo "Error: Unsupported branch '$branch'. Please use features/* or fix/*"
      exit 1
    fi

    latest_tag="$tag_prefix$major.$minor.$fix"
fi

# Write the major.minor.fix part of the tag to tag.txt in ./artifact directory
echo "$major.$minor.$fix" > "$current_dir/artifact/tag.txt"
echo "Creating new tag $latest_tag"
# Set and push the latest tag
git tag -a -m "Tag from pipeline build" "$latest_tag"
git push origin --tags
# Change back to the original directory
cd "$current_dir" || exit 1