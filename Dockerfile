FROM ubuntu:18.04

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
        libicu60 \
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
        gnupg

ENV AZ_VERSION 2.13.0-1~bionic

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
  && curl -sL https://deb.nodesource.com/setup_10.x | bash - \
  && apt-get install -y nodejs \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /etc/apt/sources.list.d/*

# Install Java OpenJDKs
RUN apt-add-repository -y ppa:openjdk-r/ppa \
  && apt-get update \
  && apt-get install -y --no-install-recommends openjdk-8-jdk \
  && rm -rf /var/lib/apt/lists/* \
  && update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java

ENV JAVA_HOME_8_X64=/usr/lib/jvm/java-8-openjdk-amd64 \
    JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
    JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8

# Install SQLPackage
RUN mkdir /opt/sqlpackage \
    && wget -O sqlpackage-linux.zip ${SQLPACKAGE_URL} \
    && unzip sqlpackage-linux.zip -d /opt/sqlpackage \
    && chmod a+x /opt/sqlpackage/sqlpackage \
    && ln -s /opt/sqlpackage/sqlpackage /usr/bin/sqlpackage

# Install MSSQL Tools
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - > /dev/null \
    && curl https://packages.microsoft.com/config/ubuntu/18.04/prod.list | tee /etc/apt/sources.list.d/msprod.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install mssql-tools unixodbc-dev \
    && ln -s /opt/mssql-tools/bin/sqlcmd /usr/bin/sqlcmd \
    && ln -s /opt/mssql-tools/bin/bcp /usr/bin/bcp

WORKDIR /azp

COPY ./start.sh .
RUN chmod +x start.sh

CMD ["./start.sh"]
