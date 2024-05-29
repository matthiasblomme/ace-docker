#!/bin/bash

# This script extracts unique project names from .descriptor files and writes them to dependencies.txt.
# It then downloads the required project dependencies from S3 and deploys them.
# This ensures that all necessary dependencies are available for the build process.

# Set base variables
gitlab_base_url="https://gitlab.com/api/v4/projects"
gitlab_project_id="47003423"
ACCESS_TOKEN=$RETREIVE_PACKAGE_REGISTRY

# Declare arrays to store project names
project_names=()
final_project_names=()
search_path="/home/aceuser/ace-server/run/"
dependencies_file="./artifact/dependencies.txt"

# Function to get the version of a specific package from the array of package versions
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

# Always add default dependencies from the dependencies file
while IFS= read -r dependency; do
  project_names+=("${dependency%.bar}")
done < "$dependencies_file"

# Get all latest package versions by running another script and reading its output into an array
IFS=$'\n' read -r -d '' -a package_versions < <(/home/aceuser/scripts/get_gitlab_package_registry_latest_version.sh && printf '\0')

# Main loop to continuously find and download required projects until no new projects are found
while true; do
    # Find all project dependencies and add them to the project_names array
    for file in $(find $search_path -type f -name "*.descriptor"); do
        while IFS= read -r project_name; do
            project_names+=("$project_name")
        done < <(grep -oP '(?<=<libraryName>).*?(?=</libraryName>)' "$file")
    done

    # Check directories already present
    readarray -d '' directories < <(find "$search_path" -mindepth 1 -maxdepth 1 -type d -print0)
    for project_name in "${project_names[@]}"; do
        found=false
        for dir in "${directories[@]}"; do
            dir_basename=$(basename "$dir")
            if [ "$project_name" = "$dir_basename" ]; then
                found=true
                break
            fi
        done
        if [ "$found" = false ]; then
            final_project_names+=("$project_name")
        fi
    done

    # Download and deploy the required projects
    for name in "${final_project_names[@]}"; do
        echo "Downloading required project: $name"
        latest_version=$(get_version_of_package "$name")

        # Fail if the latest version is not found
        if [ "$latest_version" = "Package not found" ]; then
          echo "Package $name not found, terminating"
          exit 1
        fi

        # Construct the GitLab download URL and download the file
        download_url=${gitlab_base_url}/${gitlab_project_id}/packages/generic/${name}/${latest_version}/${name}.bar
        echo "Retrieving $download_url"
        curl --header "PRIVATE-TOKEN: ${ACCESS_TOKEN}" "$download_url" --output /home/aceuser/sources/${name}.bar
        echo "Deploying ${name}.bar"
        /home/aceuser/scripts/deploy.sh /home/aceuser/sources/${name}.bar
    done

    # Break the loop if no new project names were added
    if [ ${#final_project_names[@]} -eq 0 ]; then
        break
    fi

    # Reset final_project_names for the next iteration
    unset final_project_names
done

# Clear the output file and remove duplicates from the project_names array
> "./artifact/dependencies.txt"
unique_project_names=($(echo "${project_names[@]}" | tr ' ' '\n' | sort -u))

# Add unique project names to the dependencies file
for project in "${unique_project_names[@]}"; do
  echo "$project.bar" >> ./artifact/dependencies.txt
done
