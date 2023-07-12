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

ibmint deploy --input-bar-file "$barFile" --output-work-directory "$workDir"
