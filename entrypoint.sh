#!/bin/sh -l

echo "aws-access-key-id: $AWS_ACCESS_KEY_ID"
echo "aws-secret-access-key: $AWS_SECRET_ACCESS_KEY"
echo "config: $CONFIG"
cd tailcall-on-aws
terraform init