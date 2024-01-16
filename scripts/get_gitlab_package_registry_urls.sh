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

# Get all latest package versions
IFS=$'\n' read -r -d '' -a package_versions < <(./get_gitlab_package_registry_latest_version.sh && printf '\0')

# Initialize an empty array to store the URLs
urls=()

# Loop through each package name and retrieve the latest version from CodeArtifact
for package in "${package_names[@]}"; do
  # Get the latest version of the package from CodeArtifact
  latest_version=$(get_version_of_package "$name")
  download_url=${gitlab_base_url}/${gitlab_project_id}/packages/generic/${package_name}/${latest_version}/${name}.bar
  # Append the URL to the array
  urls+=("    - '$download_url'")
done

# Print the URLs
for url in "${urls[@]}"; do
  echo "$url"
done
