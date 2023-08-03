#!/bin/bash
workDir=/home/aceuser/ace-server
echo "Creating integration server BUILD_IS from $workDir"
ibmint optimize server --work-directory  $workDir
IntegrationServer --work-dir "$workDir" --name BUILD_IS > $workDir/console.logaws