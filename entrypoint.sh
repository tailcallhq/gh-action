#!/bin/sh -l

set -e

get_latest_release() {
  curl https://api.github.com/repos/$1/$2/releases/latest -s | jq .name -r
}

export TF_VAR_AWS_REGION=$AWS_REGION
export TF_VAR_AWS_IAM_ROLE=$AWS_IAM_ROLE
export TF_VAR_AWS_LAMBDA_FUNCTION_NAME=$AWS_LAMBDA_FUNCTION_NAME

if [ "$TAILCALL_VERSION" = "latest" ]; then
  TAILCALL_VERSION=$(get_latest_release tailcallhq tailcall)
fi
export TF_VAR_TAILCALL_VERSION=$TAILCALL_VERSION

get_tailcall_config() {
  cp "$TAILCALL_CONFIG" .
}

setup_terraform() {
  TERRAFORM_VERSION=$(get_latest_release hashicorp terraform)
  cd /usr/local/bin
  curl https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip
  unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
  rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
}

setup_flyctl() {
  curl -L https://fly.io/install.sh | sh
  export FLYCTL_INSTALL="/root/.fly"
  export PATH="$FLYCTL_INSTALL/bin:$PATH"
}

if [ "$PROVIDER" = "aws" ]; then
  install_terraform
  cd /aws
  get_tailcall_config
  terraform init
  terraform apply -auto-approve
elif [ "$PROVIDER" = "fly" ]; then
  install_flyctl
  cd /fly
  get_tailcall_config
  flyctl deploy
fi