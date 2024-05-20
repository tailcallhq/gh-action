#!/bin/sh -l

echo "aws-access-key-id: $AWS_ACCESS_KEY_ID"
echo "aws-secret-access-key: $AWS_SECRET_ACCESS_KEY"
echo "config: $CONFIG"
echo "LS: $(ls)"
echo "TF_CONTENT: $(TF_CONTENT)"
cd /tmp
terraform init
TF_VAR_AWS_REGION=$AWS_REGION TF_VAR_CONFIG_PATH=$CONFIG terraform apply