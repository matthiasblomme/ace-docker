#!/bin/bash

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

# Load mqsi profile
. /opt/ibm/ace-12/server/bin/mqsiprofile

# Insert default dependency
echo "CustomNodes.bar" >> ./artifact/dependencies.txt

# Deploy to resolve dependencies
echo "running ibmint deploy --input-path $sourceDir --output-work-directory $workDir"
ibmint deploy --input-path $sourceDir --output-work-directory $workDir

# Download al dependencies
/home/aceuser/scripts/extract_project_names.sh

# List the applications
applicationList=$(find /home/aceuser/sources/${BUILD_PROJECT_NAME} -maxdepth 1 -mindepth 1 -type d ! -name '.*' ! -name 'soapui' ! -name 'readme' -print | sort | xargs -I {} basename {} | tr '\n' ' ')
echo "applications: $applicationList"

# List the libraries/dependencies
libraryList=$(find /home/aceuser/ace-server/run -maxdepth 1 -mindepth 1 -type d ! -name '.*' ! -name 'soapui' ! -name 'readme' ! -name ${BUILD_PROJECT_NAME}  -print0 | xargs -0 -I {} basename {} | tr '\n' ' ')
echo "libraries: $libraryList"

#g Gt all latest package versions
IFS=$'\n' read -r -d '' -a package_versions < <(/home/aceuser/scripts/get_gitlab_package_registry_latest_version.sh && printf '\0')

# Clone dependency sources
for library in $libraryList; do
  latest_version=$(get_version_of_package $library)
  # Clone to libraries dir
  echo "Cloning ${library}-v${latest_version}"
  git -c advice.detachedHead=false clone --branch "${library}-v${latest_version}" "https://gitlab-ci-token:${ESB_GROUP_ACCESS_TOKEN}@gitlab.com/luminusbe/luminusbe-digital/esb/libraries/${library}" "/home/aceuser/sources/libraries/${library}"

  # Copy library source folders to build path
  find "/home/aceuser/sources/libraries/${library}" -maxdepth 1 -mindepth 1 -type d ! -name '.*' ! -name 'readme' -print0 | xargs -0 -I {} cp -r {} /home/aceuser/sources/${BUILD_PROJECT_NAME}/
done

# Echo directory contents of /home/aceuser/sources/libraries
echo "Retreived dependencies:"
ls -l /home/aceuser/sources/libraries

#build code with all dependencies
echo "/home/aceuser/scripts/buildBar.sh /home/aceuser/sources/${BUILD_PROJECT_NAME} $applicationList $libraryList"
/home/aceuser/scripts/buildBar.sh /home/aceuser/sources/${BUILD_PROJECT_NAME} $applicationList $libraryList