#!/bin/bash

AWS_CA_REPO="ESB-Artifacts"
AWS_CA_DOMAIN="luminus"
AWS_CA_DOMAIN_OWNER="281885323515"
AWS_REGION="eu-west-3"
input_file="$1"

aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set region $AWS_REGION

# Read the list of package names from the input file into an array
mapfile -t package_names < "$input_file"

# Initialize an empty array to store the URLs
urls=()

# Loop through each package name and retrieve the latest version from CodeArtifact
for package in "${package_names[@]}"; do
  # Get the latest version of the package from S3
  download_url=$(aws s3 presign "s3://${S3_ARTIFACT_BUCKET}/$package")
  # Append the URL to the array
  urls+=("    - '$download_url'")
done

# Print the URLs
for url in "${urls[@]}"; do
  echo "$url"
done
