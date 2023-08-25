#!/bin/bash

#store command line parameters
output_path=$1
properties_file=$2

#read properties file line by line
echo "reading $properties_file"
while IFS=';' read -r file_name template_file properties; do
  # Split properties into key-value pairs
  IFS=';' read -ra key_values <<< "$properties"
  output_file="${output_path}/${file_name}.yaml"
  #clear the file if it exists
  echo '' > $output_file
  template_file="/home/aceuser/runtimedefinitions/_Template/${template_file}.yaml"
  echo "creating $output_file from $template_file"
  # Open the template file for reading and the new file for writing
  while IFS= read -r line; do
    for key_value in "${key_values[@]}"; do
      # Use regex to separate key and value
      if [[ "$key_value" =~ ([^=]*)=(.*) ]]; then
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        line="${line//\$\$$key\$\$/$value}"
      fi
    done
    echo "$line" >> "$output_file"
  done < "$template_file"
done < "$properties_file"