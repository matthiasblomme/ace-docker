#!/bin/bash

# This script rund the ibmint package command in order to build a bar for the projects that
# are supplied via the command line arguments

# Get the first input parameter as the source directory and shift it out of the parameter list
sourceDir=$1
shift
echo "sourceDir: $sourceDir"

# Get the next input parameter as the project name
projectName=$1
echo "projectName: $projectName"

# Define base directories and file paths
artefactDir=/home/aceuser/artefact
echo "artefactDir: $artefactDir"
barFile="$artefactDir/$projectName.bar"
echo "barFile: $barFile"
workDir=/home/aceuser/ace-server
echo "workDir: $workDir"

# Load the IBM MQSI profile for setting up the environment variables required by ACE
. /opt/ibm/ace-12/server/bin/mqsiprofile

# Shift out the project name from the parameter list and initialize project flags for the ibmint command
shift
projectFlags="--project $projectName"

# Iterate through remaining parameters (additional project names) and add them to project flags
while [[ $# -gt 0 ]]; do
  projectFlags+=" --project $1"
  shift
done

# Run the ibmint package command to create the bar file
echo "running ibmint package --input-path $sourceDir --output-bar-file $barFile --compile-maps-and-schemas $projectFlags --trace /home/aceuser/sources/trace.log"
ibmint package --input-path $sourceDir --output-bar-file "$barFile" --compile-maps-and-schemas $projectFlags --trace /home/aceuser/sources/trace.log

# Check if the bar file was created successfully, if not, exit with an error
if [ ! -f "$barFile" ]; then
    echo "failed to create $barFile"
    exit 1
fi

# Print success message
echo "created $barFile"
