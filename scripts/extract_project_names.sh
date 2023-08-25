#!/bin/bash

AWS_CA_REPO="ESB-Artifacts"
AWS_CA_DOMAIN="luminus"
AWS_CA_DOMAIN_OWNER="281885323515"
AWS_REGION="eu-west-3"

aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set region $AWS_REGION

aws codeartifact get-authorization-token \
    --domain $AWS_CA_DOMAIN \
    --domain-owner $AWS_CA_DOMAIN_OWNER \
    --query authorizationToken \
    --output text > auth.txt
export AWS_CODEARTIFACT_AUTH_TOKEN=$(cat auth.txt)
aws codeartifact login \
    --tool twine \
    --repository $AWS_CA_REPO \
    --domain $AWS_CA_DOMAIN \
    --domain-owner $AWS_CA_DOMAIN_OWNER \
    --region $AWS_REGION

# Declare an empty array to store required project names
project_names=()
final_project_names=()
search_path="/home/aceuser/ace-server/run/"
dependencies_file="./artifact/dependencies.txt"

# Always add default dependencies
while IFS= read -r dependency; do
  project_names+=("${dependency%.bar}")
done < "$dependencies_file"

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
	  # Add to dependencies
	  echo "$name.bar" >> ./artifact/dependencies.txt
		echo "Downloading required project: $name"
		latest_version=$(aws codeartifact list-package-versions \
        --domain $AWS_CA_DOMAIN \
        --domain-owner $AWS_CA_DOMAIN_OWNER \
        --repository $AWS_CA_REPO \
        --format generic \
        --namespace esb-artifacts \
        --package "${name}.bar" \
        --output json | awk -F '"' '/"version":/{print $4}' | sort -r | head -n 1)
    aws codeartifact get-package-version-asset \
      --domain $AWS_CA_DOMAIN \
      --domain-owner $AWS_CA_DOMAIN_OWNER \
      --repository $AWS_CA_REPO \
      --format generic \
      --namespace esb-artifacts \
      --package "${name}.bar" \
      --package-version "$latest_version" \
      --asset "${name}.bar" \
      /home/aceuser/sources/${name}.bar

		echo "Deploying ${name}.bar"
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