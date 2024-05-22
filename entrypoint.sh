#!/bin/sh -l

set -e

export TF_VAR_AWS_REGION=$AWS_REGION
export TF_VAR_CONFIG_PATH=$CONFIG
export TF_VAR_AWS_IAM_ROLE=$AWS_IAM_ROLE
export TF_VAR_AWS_LAMBDA_FUNCTION_NAME=$AWS_LAMBDA_FUNCTION_NAME
cp $TAILCALL_CONFIG /tmp/config.graphql

cd /tmp
terraform init
terraform apply -auto-approve