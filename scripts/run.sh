#!/bin/bash

# This script sources the ACE environment profile and starts the integration server using the given work directory.
# It waits for the server to start and writed the console output to console.log

# Source the ACE profile to set up the environment
. /opt/ibm/ace-12/server/bin/mqsiprofile

# Set the working directory for the integration server
workDir=/home/aceuser/ace-server

# Print the Java version to confirm Java is correctly installed and configured
java -version

# Create an optimized integration server instance named 'BUILD_IS' using the specified work directory
echo "Creating integration server BUILD_IS from $workDir"
ibmint optimize server --work-directory  $workDir

# Start the integration server with the specified work directory and name, and redirect output to console.log
IntegrationServer --work-dir "$workDir" --name BUILD_IS > $workDir/console.log
