#!/bin/bash

# Get variables from input params
sourceDir=$1
shift
echo "sourceDir: $sourceDir"
projectName=$1
echo "projectName: $projectName"

# Define base variables
artefactDir=/home/aceuser/artefact
echo "artefactDir: $artefactDir"
barFile="$artefactDir/$projectName.bar"
echo "barFile: $barFile"
workDir=/home/aceuser/ace-server
echo "workDir: $workDir"

# Load mqsi profile
. /opt/ibm/ace-12/server/bin/mqsiprofile

# Get remaining params as project names
shift
projectFlags="--project $projectName"

while [[ $# -gt 0 ]]; do
  projectFlags+=" --project $1"
  shift
done

# Run the packaging command
echo "running ibmint package --input-path $sourceDir --output-bar-file $barFile --compile-maps-and-schemas $projectFlags --trace /home/aceuser/sources/trace.log"
ibmint package --input-path $sourceDir --output-bar-file "$barFile" --compile-maps-and-schemas $projectFlags --trace /home/aceuser/sources/trace.log

# Fail if no bar file created
if [ ! -f "$barFile" ]; then
    echo "failed to create $barFile"
    exit 1
fi
echo "created $barFile"