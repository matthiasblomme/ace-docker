#!/bin/bash

# This script generates an integration runtime custom resource (CR) for ACE based on a provided template.
# It replaces placeholders in the template with actual values from a properties file.
# The resulting CR is saved to a specified output directory, ready for deployment.

# Store command line parameters
input_file=$1  # Path to the input template file
output_file=$2  # Path to the output file to be created
dependencies_file=$3  # Path to the file containing dependency information
configurations_file=$4  # Path to the file containing configuration information
shared_configurations_file=$5  # Path to the file containing shared configuration information (like gitlabpackageregistryauth)

# Retrieve bar URLs using an external script
bar_urls="$(/home/aceuser/scripts/get_gitlab_package_registry_urls.sh $dependencies_file)"
config_array=()

# Get configuration names from the configurations file
while IFS= read -r line; do
  second_param=$(echo "$line" | cut -d';' -f2)
  if [[ "$second_param" == "secret" ]]; then
    continue
  fi

  # Extract the value of the NAME key using regex
  if [[ $line =~ NAME=\'([^\'\"]*)\' ]]; then
    config_array+=("${BASH_REMATCH[1]}")
  fi
done < "$shared_configurations_file"

# Get configuration names from the configurations file
while IFS= read -r line; do
  second_param=$(echo "$line" | cut -d';' -f2)
  if [[ "$second_param" == "secret" ]]; then
    continue
  fi
  # Extract the value of the NAME key using regex
  if [[ $line =~ NAME=\'([^\'\"]*)\' ]]; then
    config_array+=("${BASH_REMATCH[1]}")
  fi
done < "$configurations_file"

# Clear the output file if it exists
echo '' > "$output_file"

# Process the input file line by line
while IFS= read -r line; do
  write_original=true  # Flag to determine if the original line should be written

  # Replace $$barUrls$$ placeholder with actual bar URLs
  if [[ $line == *"\$\$barUrls\$\$"* ]]; then
    echo "$bar_urls" >> "$output_file"
    write_original=false
  fi

  # Replace $$configurationNames$$ placeholder with actual configuration names
  if [[ $line == *"\$\$configurationNames\$\$"* ]]; then
    for config_entry in "${config_array[@]}"; do
        echo "    - $config_entry" >> "$output_file"
    done
    write_original=false
  fi

  # Replace $$IrName$$ placeholder with the lower case project name
  if [[ $line == *"\$\$IrName\$\$"* ]]; then
    lower_case_project_name=$(echo $BUILD_PROJECT_NAME | tr '[:upper:]' '[:lower:]')
    modified_line=${line//\$\$IrName\$\$/${lower_case_project_name}}
    echo "$modified_line" >> "$output_file"
    write_original=false
  fi

  # Replace $$AppName$$ placeholder with the project name
  if [[ $line == *"\$\$AppName\$\$"* ]]; then
    modified_line=${line//\$\$AppName\$\$/${BUILD_PROJECT_NAME}}
    echo "$modified_line" >> "$output_file"
    write_original=false
  fi

  # Write the original line if no placeholders were replaced
  if $write_original; then
    echo "$line" >> "$output_file"
  fi
done < "$input_file"

# Print success message
echo "Created $output_file"
