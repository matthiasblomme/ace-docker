#!/bin/bash

# Get the configuration file path, type, and value from the input arguments
config_file=$1
input_type=$2
input_key=$3

# Read the file line by line
while IFS=';' read -r file_name template_file properties; do
  # Split the properties into key-value pairs
  IFS=';' read -ra key_values <<< "$properties"

  # Check if the second parameter matches the input type
  if [ "$template_file" == "$input_type" ]; then
    # Loop through the key-value pairs to find the specified key
    for key_value in "${key_values[@]}"; do
      # Use regex to separate key and value
      if [[ "$key_value" =~ ^$input_key=(.*)$ ]]; then
        data_value="${BASH_REMATCH[1]}"
        echo "$data_value"
        # You can break the loop here if you only need the first match
        break
      fi
    done
  fi
done < "$config_file"
