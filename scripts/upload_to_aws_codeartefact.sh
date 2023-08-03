#!/bin/bash
BAR_FILE=$1
BAR_FILE_VERSION="0.0.0"
AWS_CA_REPO="ESB-Artifacts"
AWS_CA_DOMAIN="luminus"
AWS_CA_DOMAIN_OWNER="281885323515"
AWS_REGION="eu-west-3"

#configure aws credentials
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY

#login to aws codeartifact
aws codeartifact get-authorization-token --domain $AWS_CA_DOMAIN --domain-owner $AWS_CA_DOMAIN_OWNER --query authorizationToken --output text > auth.txt
aws codeartifact login --tool generic --repository $AWS_CA_REPO --domain $AWS_CA_DOMAIN --domain-owner $AWS_CA_DOMAIN_OWNER --region $AWS_REGION --token file://auth.txt

#determine new bar file version
aws codeartifact get-package-version-metadata --domain $AWS_CA_DOMAIN --domain-owner $AWS_CA_DOMAIN_OWNER --repository $AWS_CA_REPO --format generic --namespace esb-artifacts --package-name $BAR_FILE --query version --output text > version.txt
BAR_FILE_VERSION=$(./increment_version.sh ./version.txt)

#upload bar file
aws codeartifact upload-package --domain $AWS_CA_DOMAIN --domain-owner $AWS_CA_DOMAIN_OWNER --repository $AWS_CA_REPO --format generic --namespace esb-artifacts --package-version $BAR_FILE_VERSION --file $BAR_FILE
#cleanup authorization file
rm auth.txt