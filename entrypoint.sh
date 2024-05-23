#!/bin/sh -l

set -e

python /tmp/main.py "$@"
export TF_VAR_AWS_REGION=$AWS_REGION
export TF_VAR_AWS_IAM_ROLE=$AWS_IAM_ROLE
export TF_VAR_AWS_LAMBDA_FUNCTION_NAME=$AWS_LAMBDA_FUNCTION_NAME

if [ "$TAILCALL_VERSION" = "latest" ]; then
  TAILCALL_VERSION=$1
fi
export TF_VAR_TAILCALL_VERSION=$TAILCALL_VERSION

cp $TAILCALL_CONFIG /tmp/config.graphql

cd /tmp
#terraform init
#terraform apply -auto-approve