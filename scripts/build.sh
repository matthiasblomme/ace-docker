#!/bin/bash
projectName=$1
echo "projectName: $projectName"
sourceDir=/home/aceuser/sources
echo "sourceDir: $sourceDir"
artefactDir=/home/aceuser/artefact
echo "artefactDir: $artefactDir"
barFile="$artefactDir/$projectName.bar"
echo "barFile: $barFile"
workDir=/home/aceuser/ace-server
echo "workDir: $workDir"

. /opt/ibm/ace-12/server/bin/mqsiprofile

shift
projectFlags="--project $projectName"

while [[ $# -gt 0 ]]; do
  projectFlags+=" --project $1"
  shift
done

echo "running package --input-path $sourceDir --output-bar-file $barFile --compile-maps-and-schemas $projectFlags"
ibmint package --input-path $sourceDir --output-bar-file "$barFile" --compile-maps-and-schemas $projectFlags