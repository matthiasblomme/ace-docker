#!/bin/bash

. /opt/ibm/ace-12/server/bin/mqsiprofile

workDir=/home/aceuser/ace-server

java -version

echo "Creating integration server BUILD_IS from $workDir"
ibmint optimize server --work-directory  $workDir
IntegrationServer --work-dir "$workDir" --name BUILD_IS > $workDir/console.log