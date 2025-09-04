FROM ubuntu:24.04

# To make it easier for build and release pipelines to run apt-get,
# configure apt to not require confirmation (assume the -y argument by default)
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

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
        netcat-openbsd \
        libssl1.0 \
        apt-transport-https \
        software-properties-common \
        apt-utils \
        wget \
        unzip \
        zip \
        gnupg \
        postgresql-client \
        swaks \
        python3-pip \
        python3-venv \
        python3-requests \
        python3-packaging \
        bsdmainutils \
        gnupg2

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /usr/share/keyrings/powershell.gpg >/dev/null \
  && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/powershell.gpg] https://packages.microsoft.com/ubuntu/24.04/prod noble main" | tee /etc/apt/sources.list.d/powershell.list \
  && apt-get update \
  && apt-get install -y powershell

RUN curl -sL https://deb.nodesource.com/setup_20.x | bash - \
  && apt-get install -y nodejs

RUN npm install -g corepack \
  && corepack prepare yarn@stable --activate

# Install Azure CLI storage extension
RUN az extension add --name storage-preview

# Install Java OpenJDKs
RUN apt-get update \
  && apt-get install -y --no-install-recommends openjdk-11-jdk \
  && apt-get install -y --no-install-recommends openjdk-17-jdk

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
ARG SQLPACKAGE_URL=https://go.microsoft.com/fwlink/?linkid=2316311
RUN mkdir /opt/sqlpackage \
    && wget -O sqlpackage-linux.zip ${SQLPACKAGE_URL} \
    && unzip sqlpackage-linux.zip -d /opt/sqlpackage \
    && chmod a+x /opt/sqlpackage/sqlpackage \
    && ln -s /opt/sqlpackage/sqlpackage /usr/bin/sqlpackage

# Install MSSQL Tools
RUN ACCEPT_EULA=Y apt-get install -y --no-install-recommends mssql-tools18 unixodbc-dev \
  && ln -s /opt/mssql-tools/bin/sqlcmd /usr/bin/sqlcmd \
    && ln -s /opt/mssql-tools/bin/bcp /usr/bin/bcp

# Install Ansible
RUN add-apt-repository --yes --update ppa:ansible/ansible \
  && apt-get install -y ansible

ARG YQ_VERSION=v4.34.1
RUN wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64.tar.gz -O - | tar xz && mv yq_linux_amd64 /usr/bin/yq

# Install kubectl
RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
RUN echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
RUN apt update
RUN apt install kubectl -y

RUN rm -rf /var/lib/apt/lists/* \
  && rm -rf /etc/apt/sources.list.d/*

WORKDIR /azp

COPY ./start.sh .
RUN chmod +x start.sh

CMD ["./start.sh"]
