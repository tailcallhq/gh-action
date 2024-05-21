# Container image that runs your code
FROM amazonlinux:2

COPY entrypoint.sh /entrypoint.sh
COPY tailcall.tf /tmp/tailcall.tf
COPY config/config.graphql /tmp/config.graphql

RUN yum update \
    && yum upgrade \
    && yum install \
    && yum install -y yum-utils \
    && yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo \
    && yum -y install terraform \
    && yum -y install curl \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && source $HOME/.cargo/env \
    && git clone https://github.com/tailcallhq/tailcall \
    && cd tailcall \
    && cargo lambda build -p tailcall-aws-lambda --release \
    && cp target/lambda/release/tailcall-aws-lambda/bootstrap /tmp/bootstrap \

ENTRYPOINT ["/entrypoint.sh"]
