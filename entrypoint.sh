#!/bin/sh -l

set -e

get_latest_version() {
  curl https://api.github.com/repos/$1/$2/releases/latest -s | jq .name -r
}

export TF_VAR_AWS_REGION=$AWS_REGION
export TF_VAR_AWS_IAM_ROLE=$AWS_IAM_ROLE
export TF_VAR_AWS_LAMBDA_FUNCTION_NAME=$AWS_LAMBDA_FUNCTION_NAME

if [ "$TAILCALL_VERSION" = "latest" ]; then
  TAILCALL_VERSION=$(get_latest_version tailcallhq tailcall)
fi
export TF_VAR_TAILCALL_VERSION=$TAILCALL_VERSION

cp $TAILCALL_CONFIG /aws/config.graphql
cp $TAILCALL_CONFIG /fly/config.graphql

setup_terraform() {
  TERRAFORM_VERSION=$(get_latest_version hashicorp terraform)
  wget -O /tmp/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
  unzip /tmp/terraform.zip -d /tmp && rm /tmp/terraform.zip
  ls /tmp
  mv /tmp/*/terraform /usr/local/bin/terraform
  ls /aws
  chmod +x /aws/terraform
}

setup_flyctl() {
  curl -L https://fly.io/install.sh | sh
  export FLYCTL_INSTALL="/root/.fly"
  export PATH="$FLYCTL_INSTALL/bin:$PATH"
}

if [ "$PROVIDER" = "aws" ]; then
  cd /aws
  setup_terraform
  terraform init
  terraform apply -auto-approve
elif [ "$PROVIDER" = "fly" ]; then
  setup_flyctl
  cd /fly
  flyctl deploy
fi