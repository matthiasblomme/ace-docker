#!/bin/bash

# This script does all the preperations before we can build a bar file.
# It deploys seperate artefacts in order to determine all the required
# libraries and dependences we need for the build. The latest version of
# these dependencies are download

# Define base variables
sourceDir=/home/aceuser/sources/${BUILD_PROJECT_NAME}
workDir=/home/aceuser/ace-server

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

# Load mqsi profile to set up the environment for ACE commands
. /opt/ibm/ace-12/server/bin/mqsiprofile

# Deploy the project to resolve dependencies
printf "\n"
echo "running ibmint deploy --input-path $sourceDir --output-work-directory $workDir"
ibmint deploy --input-path $sourceDir --output-work-directory $workDir

# Download all dependencies
/home/aceuser/scripts/extract_project_names.sh
if [ $? -eq 1 ]; then
    echo "Failed to download dependencies, terminating"
    exit 1
fi

# List the applications to be built
printf "\n"
echo "Building with: "
applicationList=$(find /home/aceuser/sources/${BUILD_PROJECT_NAME} -maxdepth 1 -mindepth 1 -type d ! -name '.*' ! -name 'soapui' ! -name 'readme' -print | sort | xargs -I {} basename {} | tr '\n' ' ')
echo "applications: $applicationList"

# List the libraries/dependencies
libraryList=$(find /home/aceuser/ace-server/run -maxdepth 1 -mindepth 1 -type d ! -name '.*' ! -name 'soapui' ! -name 'readme' ! -name ${BUILD_PROJECT_NAME}  -print0 | xargs -0 -I {} basename {} | tr '\n' ' ')
echo "libraries: $libraryList"

# Get all latest package versions
IFS=$'\n' read -r -d '' -a package_versions < <(/home/aceuser/scripts/get_gitlab_package_registry_latest_version.sh && printf '\0')

# Retrieve dependencies
printf "\n"
echo "Retreiving dependencies"
for library in $libraryList; do
  latest_version=$(get_version_of_package $library)
  # Clone to libraries dir
  echo "Cloning ${library}-v${latest_version}"
  git -c advice.detachedHead=false clone --branch "${library}-v${latest_version}" "https://gitlab-ci-token:${ESB_GROUP_ACCESS_TOKEN}@gitlab.com/luminusbe/luminusbe-digital/esb/libraries/${library}" "/home/aceuser/sources/libraries/${library}"

  # Copy library source folders to build path
  find "/home/aceuser/sources/libraries/${library}" -maxdepth 1 -mindepth 1 -type d ! -name '.*' ! -name 'readme' -print0 | xargs -0 -I {} cp -r {} /home/aceuser/sources/${BUILD_PROJECT_NAME}/
done

# Echo directory contents of /home/aceuser/sources/libraries
printf "\n"
echo "Retreived dependencies:"
ls -l /home/aceuser/sources/libraries

# Build the BAR file with all dependencies
printf "\n"
echo "building the bar file"
echo "/home/aceuser/scripts/buildBar.sh /home/aceuser/sources/${BUILD_PROJECT_NAME} $applicationList $libraryList"
/home/aceuser/scripts/buildBar.sh /home/aceuser/sources/${BUILD_PROJECT_NAME} $applicationList $libraryList
