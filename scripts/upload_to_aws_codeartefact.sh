#!/bin/bash
BAR_FILE=$1
TAG_FILE=$2
AWS_CA_REPO="ESB-Artifacts"
AWS_CA_DOMAIN="luminus"
AWS_CA_DOMAIN_OWNER="281885323515"
AWS_REGION="eu-west-3"
#run:
#/home/aceuser/scripts/upload_to_aws_codeartefact.sh ./artifact/$BUILD_PROJECT_NAME.bar ./artifact/tag.txt

#configure aws credentials
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set region $AWS_REGION

#login to aws codeartifact
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

BAR_FILE_VERSION=$(cat $TAG_FILE | tr -d '\n')

#upload bar file
upload_response=$(aws codeartifact publish-package-version \
    --domain $AWS_CA_DOMAIN \
    --domain-owner $AWS_CA_DOMAIN_OWNER \
    --repository $AWS_CA_REPO \
    --format generic \
    --namespace esb-artifacts \
    --package "$(basename $BAR_FILE)" \
    --package-version $BAR_FILE_VERSION \
    --asset-name "$(basename $BAR_FILE)" \
    --asset-content $BAR_FILE \
    --asset-sha256 "$(sha256sum $BAR_FILE | awk '{print $1}')")
echo "$upload_response"

#build codeartifact url
artifact_url="https://${AWS_CA_DOMAIN}-${AWS_CA_DOMAIN_OWNER}.d.codeartifact.$AWS_REGION.amazonaws.com/generic/$AWS_CA_REPO/$(basename $BAR_FILE)/$BAR_FILE_VERSION/$(basename $BAR_FILE)"
echo "Uploaded Artifact URL: $artifact_url"
#cleanup authorization file
rm auth.txt