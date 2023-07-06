#!/bin/bash
barFile=$1
echo "barFile: $barFile"
workDir=/home/aceuser/ace-server
echo "workDir: $workDir"

. /opt/ibm/ace-12/server/bin/mqsiprofile

echo "running deploy --input-bar-file $barFile --output-work-directory $workDir"
ibmint deploy --input-bar-file "$barFile" --output-work-directory "$workDir"

echo "running IntegrationServer --work-dir $workDir --name BUILD_IS"
IntegrationServer --work-dir "$workDir" --name BUILD_IS