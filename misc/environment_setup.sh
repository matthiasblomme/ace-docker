export TRIGGER_PROJECT=luminusbe/luminusbe-digital/esb/applications/LegalEntityRegistry
export TRIGGER_PROJECT_BRANCH=feature/testPipelineTrigger
export CI_PROJECT_PATH=luminusbe/luminusbe-digital/esb/pipeline/esb_build_pipeline
export BUILD_PROJECT_NAME=LegalEntityRegistry
export GLPAT_APPLICATIONS=...
export RUNTIME_CONFIG_URL=gitlab.com/luminusbe/luminusbe-digital/esb/runtime/runtimeconfiguration
export GLPAT_RUNTIMEDEFINITIONS=...
export RUNTIME_DEF_URL=gitlab.com/luminusbe/luminusbe-digital/esb/runtime/runtimedefinitions
export CI_JOB_TOKEN=...
export AWS_REGION=eu-west-3
export BAR_FILE=/home/aceuser/artefact/LegalEntityRegistry.bar

git clone --branch $TRIGGER_PROJECT_BRANCH https://gitlab-ci-token:...@gitlab.com/${TRIGGER_PROJECT} /home/aceuser/sources/${BUILD_PROJECT_NAME}
git clone https://gitlab-ci-token:...@${RUNTIME_CONFIG_URL} /home/aceuser/runtimeconfiguration

grep Policies /home/aceuser/ace-server/server.conf.yaml

aws codeartifact publish-package-version \
    --domain $AWS_CA_DOMAIN \
    --domain-owner $AWS_CA_DOMAIN_OWNER \
    --repository $AWS_CA_REPO \
    --format generic \
    --namespace esb-artifacts \
    --package 'EntityLib.bar' \
    --package-version 1.0.0 \
    --asset-name 'EntityLib.bar' \
    --asset-content /home/aceuser/mapped/EntityLib.bar \
    --asset-sha256 "$(sha256sum /home/aceuser/mapped/EntityLib.bar | awk '{print $1}')"

