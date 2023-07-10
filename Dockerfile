# Build and run:
#
# docker build -t ace:12.0.4.0 -f Dockerfile .
# docker run -e LICENSE=accept -p 7600:7600 -p 7800:7800 --rm -ti ace:12.0.4.0
#
# Can also mount a volume for the work directory:
#
# docker run -e LICENSE=accept -v /what/ever/dir:/home/aceuser/ace-server -p 7600:7600 -p 7800:7800 --rm -ti ace:12.0.4.0
#
# This might require a local directory with the right permissions, or changing the userid further down . . .

#use a builder to start from
FROM registry.access.redhat.com/ubi9/ubi-minimal as builder

#install basic linux utils
RUN microdnf update -y && microdnf install -y util-linux tar unzip

# download and unzip aws cli
RUN mkdir -p /opt/aws/cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/opt/aws/awscliv2.zip"
RUN unzip /opt/aws/awscliv2.zip -d /opt/aws/cli

# download and unzip the ibm binaries
RUN mkdir -p /opt/ibm/ace-12
COPY /binaries/12.0-ACE-LINUXX64-12.0.*.0.tar.gz /opt/ibm/ace12.tar.gz
RUN tar -xvf /opt/ibm/ace12.tar.gz \
    --exclude ace-12.0.*.0/tools \
    --exclude ace-12.0.*.0/server/tools/ibm-dfdl-java.zip \
    --exclude ace-12.0.*.0/server/tools/proxyservlet.war \
    --exclude ace-12.0.*.0/server/bin/TADataCollector.sh \
    --exclude ace-12.0.*.0/server/transformationAdvisor/ta-plugin-ace.jar \
    --strip-components=1 \
    -C /opt/ibm/ace-12/


# start from clean environment
FROM registry.access.redhat.com/ubi9/ubi-minimal

#install basic linux utils
RUN microdnf update -y && microdnf install -y findutils util-linux git && microdnf clean -y all

# Force reinstall tzdata package to get zoneinfo files
RUN microdnf reinstall tzdata -y

# Install ACE and accept the license
COPY --from=builder /opt/ibm/ace-12 /opt/ibm/ace-12
RUN /opt/ibm/ace-12/ace make registry global accept license deferred \
    && useradd --uid 1001 --create-home --home-dir /home/aceuser --shell /bin/bash -G mqbrkrs aceuser \
    && su - aceuser -c "export LICENSE=accept && . /opt/ibm/ace-12/server/bin/mqsiprofile && mqsicreateworkdir /home/aceuser/ace-server" \
    && echo ". /opt/ibm/ace-12/server/bin/mqsiprofile" >> /home/aceuser/.bashrc

# Get AWS cli
COPY --from=builder /opt/aws/cli /opt/aws/cli

# Add required license as text file in Liceses directory (GPL, MIT, APACHE, Partner End User Agreement, etc)
COPY /licenses/ /licenses/

# Add build and test scripts
COPY /scripts/ /home/aceuser/scripts/

# Todo: Add build to build pipeline, this is only for local testing
COPY /runtime/ /home/aceuser/runtimeconfiguration
COPY /libraries/ /home/aceuser/ace-server/run
COPY /sources/ /home/aceuser/sources

# Create artifact directory and set proper dir authorizations
USER root
RUN mkdir /home/aceuser/artifact
RUN chown -R 1001:1001 /home/aceuser/

# As aceuser ...
USER 1001
#Install AWS CLI
RUN /opt/aws/cli/aws/install -i ~/.local/aws-cli -b ~/.local/bin

# Setup aws cli environment
ENV AWS_ACCESS_KEY_ID=aa \
    AWS_SECRET_ACCESS_KEY=aa
RUN /home/aceuser/.local/bin/aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
RUN /home/aceuser/.local/bin/aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
#RUN aws s3 cp s3://esb-binaries/12.0-ACE-LINUXX64-12.0.9.0.tar.gz /opt/ibm/ace-12/ace.tar.gz

# Expose ports.  7600, 7800, 7843 for ACE;
EXPOSE 7600 7800 7843

# Set entrypoint for login shell
WORKDIR "/home/aceuser/ace-server"