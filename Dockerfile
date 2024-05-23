FROM alpine:latest as builder

RUN apk add --no-cache curl jq
RUN if [ "$TAILCALL_VERSION" = "latest" ]; then TAILCALL_VERSION=$(curl https://api.github.com/repos/tailcallhq/tailcall/releases/latest -s | jq .name -r); fi

FROM hashicorp/terraform:latest

COPY entrypoint.sh /entrypoint.sh
COPY tailcall.tf /tmp/tailcall.tf
COPY $TAILCALL_CONFIG /tmp/config.graphql
ENV TF_VAR_TAILCALL_VERSION $TAILCALL_VERSION

ENV TF_VAR_AWS_REGION $AWS_REGION
ENV TF_VAR_AWS_IAM_ROLE $AWS_IAM_ROLE
ENV TF_VAR_AWS_LAMBDA_FUNCTION_NAME $AWS_LAMBDA_FUNCTION_NAME
ENV TAILCALL_VERSION 'latest'

WORKDIR /tmp
ENTRYPOINT terraform init && terraform apply -auto-approve