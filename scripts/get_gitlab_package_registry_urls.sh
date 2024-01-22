#!/bin/bash

#  Base variables
gitlab_base_url="https://gitlab.com/api/v4/projects"
gitlab_project_id="47003423"

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <input_file>"
  exit 1
fi

input_file="$1"

# Read the list of package names from the input file into an array
mapfile -t package_names < "$input_file"

# Function to get version of a specific package
get_version_of_package() {
    local package_name=$1
    for entry in "${package_versions[@]}"; do
        if [[ $entry == "$package_name:"* ]]; then
            echo "${entry#*: }"
            return
        fi
    done
    echo "Package not found"
}

# Get all latest package versions
IFS=$'\n' read -r -d '' -a package_versions < <(/home/aceuser/scripts/get_gitlab_package_registry_latest_version.sh && printf '\0')

# Initialize an empty array to store the URLs
urls=()

# Loop through each package name and retrieve the latest version from CodeArtifact
for package in "${package_names[@]}"; do
  name="${package%.bar}"
  #echo "Getting latest version of $name"
  latest_version=$(get_version_of_package "$name")
  download_url=${gitlab_base_url}/${gitlab_project_id}/packages/generic/${name}/${latest_version}/${name}.bar
  # Append the URL to the array
  urls+=("    - '$download_url'")
done

# Print the URLs
for url in "${urls[@]}"; do
  echo "$url"
done
