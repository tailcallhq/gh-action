#!/bin/sh -l

echo "aws-access-key-id: $1"
echo "aws-secret-access-key: $2"
echo "config: $3"
cd tailcall-on-aws
terraform init