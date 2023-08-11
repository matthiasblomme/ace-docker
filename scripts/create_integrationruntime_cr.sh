#!/bin/bash

#store command line parameters
input_file=$1
output_file=$2
dependencies_file=$3
configurations_file=$4

#get bar urls
bar_urls="$(/home/aceuser/scripts/get_codeArtefact_urls.sh $dependencies_file)";
#get config urls
config_array="$(/home/aceuser/scripts/get_codeArtefact_urls.sh $configurations_file)";

#clear the file if it exists
echo '' > $output_file

while IFS= read -r line; do
  write_original=true
  if [[ $line == *"\$\$barUrls\$\$"* ]]; then
    echo "$bar_urls" >> "$output_file"
    write_original=false
  fi

  if [[ $line == *"\$\$configurationNames\$\$"* ]]; then
    echo "$config_array" >> "$output_file"
    write_original=false
  fi

  if [[ $line == *"\$\$IrName\$\$"* ]]; then
    modified_line=${line//\$\$IrName\$\$/${BUILD_PROJECT_NAME}}
    echo "$modified_line" >> "$output_file"
    write_original=false
  fi

  if [[ $line == *"\$\$AppName\$\$"* ]]; then
    modified_line=${line//\$\$AppName\$\$/${BUILD_PROJECT_NAME}}
    echo "$modified_line" >> "$output_file"
    write_original=false
  fi

  if $write_original; then
    echo "$line" >> "$output_file"
  fi
done < "$input_file"
