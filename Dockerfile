# Container image that runs your code
FROM debian:latest

COPY entrypoint.sh /entrypoint.sh
COPY tailcall.tf /tmp/tailcall.tf
COPY config/config.graphql /tmp/config.graphql

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
    && apt-get install -y curl \
    && curl -O https://github.com/tailcallhq/tailcall/releases/download/v0.82.21/tailcall-aws-lambda-bootstrap \
    && chmod +x tailcall-aws-lambda-bootstrap \
    && ./tailcall-aws-lambda-bootstrap \

ENTRYPOINT ["/entrypoint.sh"]
