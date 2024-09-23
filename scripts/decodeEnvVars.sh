#!/bin/bash

# Define the path to the input file
input_file="/home/aceuser/generic/environmentVariables.txt"

# Check if the vault directory exists, otherwise create it
if [ ! -d /home/aceuser/ace-server/config/vault ]; then
  echo "Vault directory not found. Stopping."
  exit 0
fi

# Check if the input file exists
if [ ! -f "$input_file" ]; then
  echo "Input file '$input_file' not found. Stopping cleanly."
  exit 0
fi

# Begin the output for environment variables
echo "---"
echo "EnvironmentVariables:"

# Loop through each line in the input file
while IFS= read -r line; do
    # Parse the line into type, name, and item
    type=$(echo "$line" | awk '{print $1}')
    name=$(echo "$line" | awk '{print $2}')
    item=$(echo "$line" | awk '{print $3}')

    # Construct the decode path
    decode_path="credentials/${type}/${name}"

    # Run the mqsivault decode command
    decode_output=$(mqsivault --work-dir /home/aceuser/ace-server --vault-key $ACE_VAULT_KEY --decode "$decode_path")

    # Extract the value of the item from the JSON output
    item_value=$(echo "$decode_output" | grep -o "\"$item\":\"[^\"]*\"" | sed "s/\"$item\":\"//;s/\"//")

    # Convert the name and item to uppercase
    name_upper=$(echo "$name" | tr '[:lower:]' '[:upper:]')
    item_upper=$(echo "$item" | tr '[:lower:]' '[:upper:]')

    # Construct the environment variable name
    env_var_name="ACE_VAULT_${name_upper}_${item_upper}"

    # Export the environment variable
    export $env_var_name="$item_value"

    # Print the environment variable in the desired format
    echo "  $env_var_name: '$item_value'"

done < "$input_file"
