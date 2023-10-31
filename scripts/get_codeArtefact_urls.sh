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
    --region $AWS_REGION &> /dev/null

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <input_file>"
  exit 1
fi

input_file="$1"

# Read the list of package names from the input file into an array
mapfile -t package_names < "$input_file"

# Initialize an empty array to store the URLs
urls=()

# Loop through each package name and retrieve the latest version from CodeArtifact
for package in "${package_names[@]}"; do
  # Get the latest version of the package from CodeArtifact
  latest_version=$(aws codeartifact list-package-versions \
      --domain $AWS_CA_DOMAIN \
      --domain-owner $AWS_CA_DOMAIN_OWNER \
      --repository $AWS_CA_REPO \
      --namespace esb-artifacts \
      --package $package \
      --format generic \
      --output json | grep -o '"version": "[^"]*' | grep -o '[^"]*$' | sort -rV | head -n 1)

  download_url="https://${AWS_CA_DOMAIN}-${AWS_CA_DOMAIN_OWNER}.d.codeartifact.$AWS_REGION.amazonaws.com/generic/$AWS_CA_REPO/$package/$latest_version/$package"
  # Append the URL to the array
  urls+=("    - '$download_url'")
done

# Print the URLs
for url in "${urls[@]}"; do
  echo "$url"
done
