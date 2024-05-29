#!/bin/bash

# This script constructs the URLs of the latest versions of specified packages from the GitLab package registry.
# It processes a list of package names, fetches their latest versions, and constructs their download URLs.
# The resulting URLs are stored in an array for further use in the pipeline.

#  Base variables
gitlab_base_url="https://gitlab.com/api/v4/projects"
gitlab_project_id="47003423"

# Check if the number of arguments is exactly 1
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <input_file>"
  exit 1
fi

# The input file containing the list of package names
input_file="$1"

# Read the list of package names from the input file into an array
mapfile -t package_names < "$input_file"

# Function to get the version of a specific package
get_version_of_package() {
    local package_name=$1
    # Loop through the array of package versions to find the matching package
    for entry in "${package_versions[@]}"; do
        if [[ $entry == "$package_name:"* ]]; then
            echo "${entry#*: }"
            return
        fi
    done
    echo "Package not found"
}

# Get all latest package versions by calling the script and reading its output into an array
IFS=$'\n' read -r -d '' -a package_versions < <(/home/aceuser/scripts/get_gitlab_package_registry_latest_version.sh && printf '\0')

# Initialize an empty array to store the URLs
urls=()

# Loop through each package name and retrieve the latest version from the GitLab Package Registry
for package in "${package_names[@]}"; do
  name="${package%.bar}"
  # Retrieve the latest version of the package
  latest_version=$(get_version_of_package "$name")
  # Construct the download URL for the package
  download_url=${gitlab_base_url}/${gitlab_project_id}/packages/generic/${name}/${latest_version}/${name}.bar
  # Append the URL to the array
  urls+=("    - '$download_url'")
done

# Print the URLs
for url in "${urls[@]}"; do
  echo "$url"
done
