#!/bin/bash

# This script deploys a given BAR file to an ACE integration server.
# It uses the ibmint command to apply the deployment to the specified server.

# Assign the first argument passed to the script to the variable barFile
barFile=$1
echo "barFile: $barFile"

# Set the working directory for the deployment
workDir=/home/aceuser/ace-server
echo "workDir: $workDir"

# Source the mqsiprofile script to set up the environment for ACE
. /opt/ibm/ace-12/server/bin/mqsiprofile

# Execute the deployment command with the specified BAR file and output directory
echo "running deploy --input-bar-file $barFile --output-work-directory $workDir"
ibmint deploy --input-bar-file "$barFile" --output-work-directory "$workDir"
