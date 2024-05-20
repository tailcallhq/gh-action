# Container image that runs your code
FROM debian:latest

COPY entrypoint.sh /entrypoint.sh

RUN apt-get update \
    && apt-get install -y wget git \
    && apt-get update \
    && apt-get install -y gnupg software-properties-common \
    && wget -O- https://apt.releases.hashicorp.com/gpg | \
      gpg --dearmor | \
      tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null \
    && gpg --no-default-keyring \
        --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
        --fingerprint \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
        https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        tee /etc/apt/sources.list.d/hashicorp.list \
    && apt update \
    && apt-get install -y terraform \
    && git clone https://github.com/tailcallhq/tailcall-on-aws.git \
    && terraform init

WORKDIR /tailcall-on-aws

ENTRYPOINT ["/entrypoint.sh"]