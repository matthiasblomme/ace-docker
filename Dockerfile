# Build and run:
#
# docker build -t matthiasblomme/ace.runner:12.0.12.8  --file ./Dockerfile . --build-arg ACE_VERSION=12.0.12.8 --build-arg MQ_VERSION=9.3.5.1 --build-arg SOAPUI_VERSION=5.7.1 --build-arg AWS_ACCESS_KEY_ID=xxx --build-arg AWS_SECRET_ACCESS_KEY=xxx
# docker run --name 12.0.12.2 -e LICENSE=accept -p 7600:7600 -p 7800:7800 --rm -ti matthiasblomme/ace.runner:12.0.12.2
#
# Can also mount a volume for the work directory:
#
# docker run -e LICENSE=accept -v c:\temp\mappedDir:/home/aceuser/ace-server -p 7600:7600 -p 7800:7800 --rm -ti matthiasblomme/ace.runner:12.0.9.0
#
# This might require a local directory with the right permissions, or changing the userid further down . . .

# use a builder to start from
FROM registry.access.redhat.com/ubi9/ubi-minimal as builder

# Build arguments
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG ACE_VERSION
ARG MQ_VERSION
ARG SOAPUI_VERSION

# Set env variables
ENV AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
ENV AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
ENV ACE_VERSION=${ACE_VERSION}
ENV MQ_VERSION=${MQ_VERSION}
ENV SOAPUI_VERSION=${SOAPUI_VERSION}

# Install basic linux utils
RUN microdnf update -y && microdnf install -y util-linux tar unzip findutils binutils xz
# Download and install aws cli
#RUN echo $AWS_ACCESS_KEY_ID
#RUN echo $AWS_SECRET_ACCESS_KEY
#RUN mkdir -p /opt/aws/cli
#RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/opt/aws/awscliv2.zip"
#RUN unzip /opt/aws/awscliv2.zip -d /opt/aws/cli > /dev/null 2>&1
#RUN /opt/aws/cli/aws/install
#RUN aws --version

# Setup aws cli environment end download binaries
#RUN aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
#RUN aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
RUN mkdir -p /opt/ibm/ace-12
#RUN aws s3 cp s3://esb-binaries/12.0-ACE-LINUXX64-${ACE_VERSION}.tar.gz /opt/ibm/ace12.tar.gz
COPY /sources/12.0-ACE-LINUXX64-${ACE_VERSION}.tar.gz /opt/ibm/ace12.tar.gz
RUN mkdir -p /opt/ibm/mq-93
#RUN aws s3 cp s3://esb-binaries/${MQ_VERSION}-IBM-MQC-UbuntuLinuxX64.tar.gz /opt/ibm/mq93.tar.gz# Unzip the ibm binaries without the toolkit
COPY /sources/9.4.1.0-IBM-MQ-Advanced-for-Developers-LinuxX64.tar.gz /opt/ibm/mq93.tar.gz
RUN tar -xvf /opt/ibm/ace12.tar.gz \
    --exclude ace-12.0.*.0/tools \
    --exclude ace-12.0.*.0/server/tools/ibm-dfdl-java.zip \
    --exclude ace-12.0.*.0/server/tools/proxyservlet.war \
    --exclude ace-12.0.*.0/server/bin/TADataCollector.sh \
    --exclude ace-12.0.*.0/server/transformationAdvisor/ta-plugin-ace.jar \
    --strip-components=1 \
    -C /opt/ibm/ace-12/ > /dev/null 2>&1

# Unzip and install MQ
RUN tar -xvf /opt/ibm/mq93.tar.gz -C /opt/ibm/mq-93/
#TODO: install proper mq client
RUN /opt/ibm/mq-93/MQServer/mqlicense.sh -accept
RUN rpm -i /opt/ibm/mq-93/MQServer/MQSeriesRuntime-9.4.1-0.x86_64.rpm
RUN rpm -i /opt/ibm/mq-93/MQServer/MQSeriesGSKit-9.4.1-0.x86_64.rpm
RUN rpm -i /opt/ibm/mq-93/MQServer/MQSeriesClient-9.4.1-0.x86_64.rpm

# Download and install SoapUI
#RUN mkdir /opt/soapui
#RUN aws s3 cp s3://esb-binaries/SoapUI-${SOAPUI_VERSION}-linux-bin.tar.gz /opt/
#RUN tar -xzf /opt/SoapUI-${SOAPUI_VERSION}-linux-bin.tar.gz -C /opt/soapui --strip-components=1


# Start from clean environment
FROM registry.access.redhat.com/ubi9/ubi-minimal

# Install basic linux utils
RUN microdnf update -y && microdnf install -y findutils util-linux git tar java-11-openjdk-devel nano procps jq zip unzip && microdnf clean -y all

# Force reinstall tzdata package to get zoneinfo files
RUN microdnf reinstall tzdata -y

# Install aws cli
#COPY --from=builder /opt/aws/cli /opt/aws/cli
#RUN /opt/aws/cli/aws/install
#RUN aws --version

# Install ACE and accept the license
COPY --from=builder /opt/ibm/ace-12 /opt/ibm/ace-12
RUN /opt/ibm/ace-12/ace make registry global accept license deferred \
    && useradd --uid 1001 --create-home --home-dir /home/aceuser --shell /bin/bash -G mqbrkrs aceuser \
    && su - aceuser -c "export LICENSE=accept && . /opt/ibm/ace-12/server/bin/mqsiprofile && mqsicreateworkdir /home/aceuser/ace-server" \
    && echo ". /opt/ibm/ace-12/server/bin/mqsiprofile" >> /home/aceuser/.bashrc

# Copy MQ from builder
COPY --from=builder /opt/mqm/ /opt/mqm/

# Copy SoapUI installation from builder stage
#COPY --from=builder /opt/soapui /opt/soapui

# Set environment variables
ENV PATH="/opt/soapui/bin:${PATH}"
ENV PATH="/opt/mqm/bin:${PATH}"
ENV LD_LIBRARY_PATH="/opt/mqm/lib64:/opt/mqm/lib:${LD_LIBRARY_PATH}"
ENV MQ_LICENSE=accept

# Add required license as text file in Liceses directory (GPL, MIT, APACHE, Partner End User Agreement, etc)
COPY /licenses/ /licenses/

# Add build and test scripts
COPY /scripts/ /home/aceuser/scripts/

# Add config
COPY /config/ /home/aceuser/config/

# Create artifact directory and set proper dir authorizations
USER root
RUN mkdir /home/aceuser/artifact
RUN chown -R 1001:1001 /home/aceuser/
RUN chmod 777 /home/aceuser/scripts/
RUN chmod -R 777 /home/aceuser/config/

# Expose ports.  7600, 7800, 7843 for ACE;
EXPOSE 7600 7800 7843

# Set entrypoint for login shell
WORKDIR "/home/aceuser/ace-server"

# Source mqsi during startup
#TODO:
#ENTRYPOINT ["bash", "-c", ". /opt/ibm/ace-12/server/bin/mqsiprofile"]

# Customize
RUN alias ll='ls -la'