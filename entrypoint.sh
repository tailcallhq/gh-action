#!/bin/sh -l

set -e

get_latest_version() {
  curl https://api.github.com/repos/$1/$2/releases/latest -s | jq .name -r
}

export TF_VAR_AWS_REGION=$AWS_REGION
export TF_VAR_AWS_IAM_ROLE=$AWS_IAM_ROLE
export TF_VAR_AWS_LAMBDA_FUNCTION_NAME=$AWS_LAMBDA_FUNCTION_NAME
export TF_TOKEN_app_terraform_io=$TERRAFORM_API_TOKEN

if [ "$TAILCALL_VERSION" = "latest" ]; then
  TAILCALL_VERSION=$(get_latest_version tailcallhq tailcall)
fi
export TF_VAR_TAILCALL_VERSION=$TAILCALL_VERSION

cp $TAILCALL_CONFIG /aws/config.graphql
cp $TAILCALL_CONFIG /fly/config.graphql

setup_terraform() {
  TERRAFORM_VERSION=$(get_latest_version hashicorp terraform)
  TERRAFORM_VERSION="${TERRAFORM_VERSION:1}"
  wget -O terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
  unzip terraform.zip && rm terraform.zip
  mv terraform /usr/local/bin/terraform
}

setup_flyctl() {
  curl -L https://fly.io/install.sh | sh
  export PATH=$PATH:$HOME/.fly/bin
}

if [ "$PROVIDER" = "aws" ]; then
  cd /aws
  setup_terraform
  terraform init
  terraform plan
  terraform apply -auto-approve
elif [ "$PROVIDER" = "fly" ]; then
  setup_flyctl
  cd /fly
  flyctl launch --name $FLY_APP_NAME
fi