#!/bin/bash

#  Base variables
gitlab_base_url="https://gitlab.com/api/v4/projects"
gitlab_project_id="47003423"
ACCESS_TOKEN=$RETREIVE_PACKAGE_REGISTRY

# Declare an empty array to store required project names
project_names=()
final_project_names=()
search_path="/home/aceuser/ace-server/run/"
dependencies_file="./artifact/dependencies.txt"

# Function to get version of a specific package
get_version_of_package() {
    local package_name=$1
    for entry in "${package_versions[@]}"; do
        if [[ $entry == "$package_name:"* ]]; then
            echo "${entry#*: }"
            return
        fi
    done
    echo "Package not found"
}

# Always add default dependencies
while IFS= read -r dependency; do
  project_names+=("${dependency%.bar}")
done < "$dependencies_file"

# Get all latest package versions
IFS=$'\n' read -r -d '' -a package_versions < <(/home/aceuser/scripts/get_gitlab_package_registry_latest_version.sh && printf '\0')

# Start the main loop
while true; do
	# Find all .project files and loop through them
	for file in $(find $search_path -type f -name "*.descriptor"); do
		# Use grep with Perl-compatible regex to extract project names and add them to the array\
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
		#get the latest version
		latest_version=$(get_version_of_package "$name")

		#build gitlab download url
    download_url=${gitlab_base_url}/${gitlab_project_id}/packages/generic/${name}/${latest_version}/${name}.bar
    echo "retreiving $download_url"
    #download
    curl --header "PRIVATE-TOKEN: ${ACCESS_TOKEN}" "$download_url" --output /home/aceuser/sources/${name}.bar
		echo "Deploying ${name}.bar"
		/home/aceuser/scripts/deploy.sh /home/aceuser/sources/${name}.bar
	done

  # Check if any new project names were added during this iteration
  if [ ${#final_project_names[@]} -eq 0 ]; then
      # All dependencies have been downloaded, exit the loop
      break
  fi

	unset final_project_names
done


#clear output file
> "./artifact/dependencies.txt"
#remove duplicates
unique_project_names=($(echo "${project_names[@]}" | tr ' ' '\n' | sort -u))

for project in "${unique_project_names[@]}"; do
  # add to dependencies
  echo "$project.bar" >> ./artifact/dependencies.txt
done
