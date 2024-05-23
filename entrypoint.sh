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
  curl -s https://api.github.com/repos/tailcallhq/tailcall/releases/latest \
      | jq --raw_output .zipball_url \
      | xargs wget -O /tmp/terraform.zip
  unzip /tmp/terraform.zip -d /tmp
  go build
  mv /tmp/terraform /usr/local/bin/terraform
}

setup_flyctl() {
  curl -L https://fly.io/install.sh | sh
  export FLYCTL_INSTALL="/root/.fly"
  export PATH="$FLYCTL_INSTALL/bin:$PATH"
}

if [ "$PROVIDER" = "aws" ]; then
  cd /aws
  setup_terraform
  get_tailcall_config
  terraform init
  terraform apply -auto-approve
elif [ "$PROVIDER" = "fly" ]; then
  setup_flyctl
  cd /fly
  get_tailcall_config
  flyctl deploy
fi