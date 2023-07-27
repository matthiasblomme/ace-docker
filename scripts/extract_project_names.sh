#!/bin/bash

aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY

# Declare an empty array to store required project names
project_names=()
final_project_names=()
search_path="/home/aceuser/ace-server/run/"

# Start the main loop
while true; do

	# Find all .project files and loop through them
	for file in $(find $search_path -type f -name "*.descriptor"); do
		# Use grep with Perl-compatible regex to extract project names and add them to the array
		while IFS= read -r project_name; do
			project_names+=("$project_name")
		done < <(grep -oP '(?<=<libraryName>).*?(?=</libraryName>)' "$file")
	done

	# Find all dirs already present
	readarray -d '' directories < <(find "$search_path" -mindepth 1 -maxdepth 1 -type d -print0)
	for project_name in "${project_names[@]}"; do
		found=false
		for dir in "${directories[@]}"; do
			dir_basename=$(basename "$dir")
			if [ "$project_name" = "$dir_basename" ]; then
				found=true
				break
			fi
		done
		if [ "$found" = false ]; then
			final_project_names+=("$project_name")
		fi
	done

	# Perform download for all required projects
	for name in "${final_project_names[@]}"; do
		echo "Downloading required project: $name"
		aws s3 cp s3://esb-artefacts/${name}.bar /home/aceuser/sources/
		echo "Deploying $name"
		/home/aceuser/scripts/deploy.sh /home/aceuser/sources/${name}.bar
	done

    # Check if any new project names were added during this iteration
    if [ ${#final_project_names[@]} -eq 0 ]; then
        # All dependencies have been downloaded, exit the loop
        break
    fi

	unset final_project_names
	unset project_names
done