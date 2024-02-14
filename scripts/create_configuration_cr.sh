#!/bin/bash
# Store command line parameters
output_path=$1
resource_path=$2
properties_file=$3

# Read properties file line by line
echo "Reading $properties_file"

while IFS=';' read -r file_name template_file properties || [[ -n $properties ]]; do
  # Split properties into key-value pairs
  #if file_name is empty, stop
  if [ -z "$file_name" ]; then break fi;

  IFS=';' read -ra key_values <<< "$properties"
  output_file="${output_path}/${file_name}.yaml"
  echo "Creating $output_file"

  # Clear the file if it exists
  echo '' > "$output_file"

  template_file="/home/aceuser/runtimedefinitions/_Template/${template_file}.yaml"
  echo "From template $template_file"

  # Read template file line by line
  while IFS= read -r line; do
    # Process each line using the key-value pairs
    for key_value in "${key_values[@]}"; do
      # Use regex to separate key and value
      if [[ "$key_value" =~ ([^=]*)=(.*) ]]; then
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        if [[ "$key" == "DATA" ]]; then
          value=$(base64 -w 0 "${resource_path}/${value}")
        fi
        line="${line//\$\$$key\$\$/$value}"
      fi
    done
    echo "$line" >> "$output_file"
  done < "$template_file"
done < "$properties_file"

