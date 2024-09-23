#!/bin/bash

# This script essentially creates configuration files by applying properties defined in a properties
# file to templates, replacing placeholders in the templates with actual values.

# Store command line parameters
output_path=$1            # Path where the output file will be saved
resource_path=$2          # Path to the resource files
properties_file=$3        # Path to the properties file

# Read properties file line by line
echo "Reading $properties_file"

# Read each line in the properties file
while IFS=';' read -r file_name template_file properties || [[ -n $properties ]]; do
   # Check if properties are empty; if so, skip processing
  if [ -z "$properties" ]; then
    echo "No properties provided for $file_name, skipping."
    continue
  fi

  if [[ "$template_file" == "manuallygenerated" ]]; then
    echo "Skipping manually generated entry $file_name."
    continue
  fi

  # Split the properties part of the line into an array of key-value pairs
  IFS=';' read -ra key_values <<< "$properties"

  # Define the output file path
  output_file="${output_path}/${file_name}.yaml"
  echo "Creating $output_file"

  # Clear the file if it exists
  echo '' > "$output_file"

  # Define the template file path
  template_file="/home/aceuser/runtimedefinitions/_Template/${template_file}.yaml"
  echo "From template $template_file"

  # Read the template file line by line
  while IFS= read -r line; do
    # Process each line using the key-value pairs
    for key_value in "${key_values[@]}"; do
      # Use regex to separate key and value
      if [[ "$key_value" =~ ([^=]*)=(.*) ]]; then
        key="${BASH_REMATCH[1]}"    # Extract the key
        value="${BASH_REMATCH[2]}"  # Extract the value
        if [[ "$key" == "DATA" ]]; then
          # If the key is "DATA", encode the specified file in base64 format
          value=$(base64 -w 0 "${resource_path}/${value}")
        fi
        # Replace all occurrences of $$key$$ in the line with the corresponding value
        line="${line//\$\$$key\$\$/$value}"
      fi
    done
    # Write the processed line to the output file
    echo "$line" >> "$output_file"
  done < "$template_file"
done < "$properties_file"
