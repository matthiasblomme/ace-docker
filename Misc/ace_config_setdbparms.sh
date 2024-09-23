#!/bin/bash

# © Copyright IBM Corporation 2018.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v2.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v20.html

# Function to split a string into an array of arguments, handling spaces and special characters
function argStrings {
  # Use Python's shlex module to split the input string as if it were a shell command
  shlex() {
    python -c $'import sys, shlex\nfor arg in shlex.split(sys.stdin):\n\tsys.stdout.write(arg)\n\tsys.stdout.write(\"\\0\")'
  }

  # Initialize an empty array to store the arguments
  args=()

  # Read the arguments produced by the shlex function and store them in the args array
  while IFS='' read -r -d ''; do
    args+=( "$REPLY" )
  done < <(shlex <<<$1)
}

# Check if the MQSI_VERSION environment variable is set.
# If not, source the mqsiprofile script to set up the environment variables needed for IBM App Connect Enterprise (ACE).
if [ -z "$MQSI_VERSION" ]; then
  source /opt/ibm/ace-12/server/bin/mqsiprofile
fi

# Check if the setdbparms file exists and is not empty.
if [ -s "/home/aceuser/initial-config/setdbparms/setdbparms.txt" ]; then
  FILE=/home/aceuser/initial-config/setdbparms/setdbparms.txt

  # Save the current Internal Field Separator (IFS) and set it to handle newline characters.
  OLDIFS=${IFS}
  IFS=$'\n'

  # Iterate through each line of the setdbparms file.
  for line in $(cat $FILE | tr -d '\r'); do
    # Skip lines that start with a comment symbol (#).
    if [[ $line =~ ^\# ]]; then
      continue
    fi

    # Restore the original IFS for processing the line.
    IFS=${OLDIFS}

    # If the line starts with the "mqsisetdbparms" command, execute it directly.
    if [[ $line == mqsisetdbparms* ]]; then
      OUTPUT=`eval "$line"`
    else
      # If the line does not start with "mqsisetdbparms", use the argStrings function to parse the line into arguments.
      shlex() {
        python -c $'import sys, shlex\nfor arg in shlex.split(sys.stdin):\n\tsys.stdout.write(arg)\n\tsys.stdout.write(\"\\0\")'
      }

      # Initialize an empty array to store the arguments.
      args=()

      # Read the arguments from the line and store them in the args array.
      while IFS='' read -r -d ''; do
        args+=( "$REPLY" )
      done < <(shlex <<<$line)

      # Construct the mqsisetdbparms command with the parsed arguments and execute it.
      cmd="mqsisetdbparms -w /home/aceuser/ace-server -n \"${args[0]}\" -u \"${args[1]}\" -p \"${args[2]}\" 2>&1"
      OUTPUT=`eval "$cmd"`

      # Output the result of the command.
      echo $OUTPUT
    fi
  done
fi
