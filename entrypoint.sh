#!/bin/sh -l

echo "aws-access-key-id: $AWS_ACCESS_KEY_ID"
echo "aws-secret-access-key: $AWS_SECRET_ACCESS_KEY"
echo "config: $CONFIG"
echo "PWD: $(pwd)"
git clone https://github.com/tailcallhq/tailcall-on-aws.git
cd tailcall-on-aws
terraform init
TF_VAR_AWS_REGION=$AWS_REGION terraform apply
echo "PWD: $(pwd)"