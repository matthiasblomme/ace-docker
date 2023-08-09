#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <input_file>"
  exit 1
fi

input_file="$1"

# Read the list of package names from the input file into an array
mapfile -t package_names < "$input_file"

# Initialize an empty array to store the URLs
urls=()

# Loop through each package name and retrieve the latest version from CodeArtifact
for package in "${package_names[@]}"; do
  # Get the latest version of the package from CodeArtifact
  response=$(aws codeartifact get-package-version --domain <DOMAIN_NAME> --repository <REPO_NAME> --format <PACKAGE_FORMAT> --package "$package" --package-version latest)

  # Extract the URL from the response JSON using jq (make sure jq is installed)
  url=$(echo "$response" | jq -r '.packageVersion | .readUrl')

  # Append the URL to the array
  urls+=("    - '$url'")
done

# Print the URLs
for url in "${urls[@]}"; do
  echo "$url"
done
