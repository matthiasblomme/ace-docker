#!/bin/bash
BAR_FILE=$1
BAR_FILE_VERSION="0.0.0"
AWS_CA_REPO="ESB-Artifacts"
AWS_CA_DOMAIN="luminus"
AWS_CA_DOMAIN_OWNER="281885323515"
AWS_REGION="eu-west-3"

#configure aws credentials
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID$AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set region $AWS_REGION

#login to aws codeartifact
aws codeartifact get-authorization-token \
    --domain $AWS_CA_DOMAIN \
    --domain-owner $AWS_CA_DOMAIN_OWNER \
    --query authorizationToken \
    --output text > auth.txt
export AWS_PROFILE=./auth.txt
aws codeartifact login \
    --tool twine \
    --repository $AWS_CA_REPO \
    --domain $AWS_CA_DOMAIN \
    --domain-owner $AWS_CA_DOMAIN_OWNER \
    --region $AWS_REGION

#determine new bar file version
aws codeartifact list-package-versions \
    --domain $AWS_CA_DOMAIN \
    --domain-owner $AWS_CA_DOMAIN_OWNER \
    --repository $AWS_CA_REPO \
    --format generic \
    --namespace esb-artifacts \
    --package-name '$(basename "$BAR_FILE")' \
    --output text > version.txt
BAR_FILE_VERSION=$(./increment_version.sh ./version.txt)

#upload bar file
aws codeartifact publish-package-version \
    --domain $AWS_CA_DOMAIN \
    --domain-owner $AWS_CA_DOMAIN_OWNER \
    --repository $AWS_CA_REPO \
    --format generic \
    --namespace esb-artifacts \
    --package '$(basename "$BAR_FILE")' \
    --package-version $BAR_FILE_VERSION \
    --asset-name '$(basename "$BAR_FILE")' \
    --asset-content $BAR_FILE \
    --asset-sha256 "$(sha256sum $BAR_FILE | awk '{print $1}')"

#cleanup authorization file
rm auth.txt version.txt