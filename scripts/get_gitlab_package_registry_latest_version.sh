#!/bin/bash

# Define the GitLab project ID
PROJECT_ID="47003423"

# GitLab Personal Access Token for authentication
# Replace with your actual access token
ACCESS_TOKEN=$RETREIVE_PACKAGE_REGISTRY

# API URL
API_URL="https://gitlab.com/api/v4/projects/${PROJECT_ID}/packages?order_by=version&sort=desc&page="

# Optional package name parameter
PACKAGE_NAME=$1
PAGE=0

# Array to keep track of the latest versions
declare -A latest_versions

# Function to compare versions
version_gt() {
    IFS='.' read -ra VER1 <<< "$1"
    IFS='.' read -ra VER2 <<< "$2"

    for ((i=0; i<${#VER1[@]}; i++)); do
        if [[ -z ${VER2[i]} ]]; then
            # VER2 has less parts, VER1 is greater
            return 0
        elif (( ${VER1[i]} > ${VER2[i]} )); then
            return 0
        elif (( ${VER1[i]} < ${VER2[i]} )); then
            return 1
        fi
    done

    if [[ ${#VER1[@]} < ${#VER2[@]} ]]; then
        # VER1 has less parts, VER2 is greater
        return 1
    fi

    return 1 # versions are equal or something unexpected happened
}

# Fetch the list of packages
while :; do
    packages=$(curl -s -H "PRIVATE-TOKEN: ${ACCESS_TOKEN}" "${API_URL}${PAGE}")

    # Check if the packages variable is empty
    if [ "$packages" == "[]" ]; then
        echo "Last page found"
        break
    fi

    # Check if packages contains 401
    if [[ $packages == *"401 Unauthorized"* ]]; then
        echo "GitLab authentication failure, received 401 on ${API_URL}"
        exit 1
    fi

    # Check if packages contains 404
    if [[ $packages == *"404 Not Found"* ]]; then
        echo "GitLab connection failure, received 404 on ${API_URL}"
        exit 1
    fi

    # Parse JSON and update the latest version for each package
    while read -r name version; do
        if [ -z "${latest_versions[$name]}" ] || version_gt "$version" "${latest_versions[$name]}"; then
            latest_versions[$name]="$version"
        fi
    done < <(echo "$packages" | jq -r '.[] | "\(.name) \(.version)"')

    # Increment the page number
    ((PAGE++))
    echo "Page $PAGE"

    # Break the loop if the packages response is empty
    if [ -z "$packages" ]; then
        break
    fi
done

# Print the latest version of the specified package or all packages
if [ -z "$PACKAGE_NAME" ]; then
    for name in "${!latest_versions[@]}"; do
        echo "$name: ${latest_versions[$name]}"
    done
else
    if [ -n "${latest_versions[$PACKAGE_NAME]}" ]; then
        echo ${latest_versions[$PACKAGE_NAME]}
    else
        echo "No package found with name: $PACKAGE_NAME"
    fi
fi
