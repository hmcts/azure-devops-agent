FROM ubuntu:22.04

# To make it easier for build and release pipelines to run apt-get,
# configure apt to not require confirmation (assume the -y argument by default)
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

# Add SQLPackage URL
ARG SQLPACKAGE_URL=https://go.microsoft.com/fwlink/?linkid=2143497

RUN apt-get update \
&& apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        jq \
        git \
        iputils-ping \
        libcurl4 \
        libunwind8 \
        lsb-release \
        make \
        netcat \
        libssl1.0 \
        apt-transport-https \
        software-properties-common \
        apt-utils \
        wget \
        unzip \
        zip \
        gnupg \
        python3-venv \
        postgresql-client \
        swaks \
        python3-pip \
        python3-venv \
        python3-requests \
        python3-packaging \
        bsdmainutils

ENV AZ_VERSION 2.49.0-1~jammy

# Install Azure CLI
RUN rm -rf /var/lib/apt/lists/* \
  && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
  | tee /etc/apt/sources.list.d/azure-cli.list \
  && wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb\
  && dpkg -i packages-microsoft-prod.deb \
  && apt-get update \
  && add-apt-repository universe \
  && apt-get install powershell \
  && curl -sL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - > /dev/null \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
       azure-cli=$AZ_VERSION \
  && curl -sL https://deb.nodesource.com/setup_20.x | bash - \
  && apt-get install -y nodejs \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /etc/apt/sources.list.d/*

# Install Azure CLI storage extension
RUN az extension add --name storage-preview

# Install Java OpenJDKs
RUN apt-add-repository -y ppa:openjdk-r/ppa \
  && apt-get update \
  && apt-get install -y --no-install-recommends openjdk-11-jdk \
  && apt-get install -y --no-install-recommends openjdk-17-jdk \
  && rm -rf /var/lib/apt/lists/* \
  && update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java

ENV JAVA_HOME_11_X64=/usr/lib/jvm/java-11-openjdk-amd64 \
    JAVA_HOME_17_X64=/usr/lib/jvm/java-17-openjdk-amd64 \
    JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 \
    JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8

# Install Docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - > /dev/null \
  && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  && apt-get update \
  && apt-get install -y docker-ce

# Install SQLPackage
RUN mkdir /opt/sqlpackage \
    && wget -O sqlpackage-linux.zip ${SQLPACKAGE_URL} \
    && unzip sqlpackage-linux.zip -d /opt/sqlpackage \
    && chmod a+x /opt/sqlpackage/sqlpackage \
    && ln -s /opt/sqlpackage/sqlpackage /usr/bin/sqlpackage

# Install MSSQL Tools
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - > /dev/null \
    && curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | tee /etc/apt/sources.list.d/msprod.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install mssql-tools unixodbc-dev \
    && ln -s /opt/mssql-tools/bin/sqlcmd /usr/bin/sqlcmd \
    && ln -s /opt/mssql-tools/bin/bcp /usr/bin/bcp

# Install Ansible
RUN add-apt-repository --yes --update ppa:ansible/ansible \
  && apt-get install -y ansible

ARG YQ_VERSION=v4.34.1
RUN wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64.tar.gz -O - | tar xz && mv yq_linux_amd64 /usr/bin/yq

WORKDIR /azp

COPY ./start.sh .
RUN chmod +x start.sh

CMD ["./start.sh"]
