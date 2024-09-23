#!/bin/bash

# © Copyright IBM Corporation 2018.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v2.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v20.html

# Check if the MQSI_VERSION environment variable is set.
# If not, source the mqsiprofile script to set up the environment variables needed for IBM App Connect Enterprise (ACE).
if [ -z "$MQSI_VERSION" ]; then
  source /opt/ibm/ace-12/server/bin/mqsiprofile
fi

# Check if the credentials file exists and is not empty.
if [ -s "/home/aceuser/initial-config/vault/credentials.txt" ]; then
  FILE=/home/aceuser/initial-config/vault/credentials.txt

  # Check if the external vault key is defined in the environment variable ACE_VAULT_KEY.
  # If not, output an error message and exit.
  if [ -z "${ACE_VAULT_KEY}" ]; then
        echo "No vault password defined"
        exit 1
  fi

  # Initialize the vault by setting the external vault key.
  mqsivault --ext-vault-dir $MQSI_VAULTRC_LOCATION --vaultrc-store-ext-key  --ext-vault-key "$ACE_VAULT_KEY"

  # Create the vault with the provided key.
  mqsivault --ext-vault-dir $MQSI_VAULTRC_LOCATION --create --ext-vault-key "$ACE_VAULT_KEY"

  # Save the current Internal Field Separator (IFS) and set it to handle newline characters.
  OLDIFS=${IFS}
  IFS=$'\n'

  # Iterate through each line of the credentials file.
  for line in $(cat $FILE | tr -d '\r'); do
    # Skip lines that start with a comment symbol (#).
    if [[ $line =~ ^\# ]]; then
      continue
    fi

    # Restore the original IFS for processing the line.
    IFS=${OLDIFS}

    # If the line starts with the "mqsicredentials" command, execute it.
    if [[ $line == mqsicredentials* ]]; then
      echo "Running supplied credential commands"
      OUTPUT=`eval "$line"`
    fi
  done
fi
