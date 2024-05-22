#!/bin/sh -l

set -e

export TF_VAR_AWS_REGION=$AWS_REGION
export TF_VAR_AWS_IAM_ROLE=$AWS_IAM_ROLE
export TF_VAR_AWS_LAMBDA_FUNCTION_NAME=$AWS_LAMBDA_FUNCTION_NAME
export TF_VAR_TAILCALL_VERSION=$TAILCALL_VERSION
mv $TAILCALL_CONFIG /tmp/config.graphql

cd /tmp
terraform init
terraform apply -auto-approve