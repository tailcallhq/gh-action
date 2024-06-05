#!/bin/bash -l

set -e

setup_tailcall() {
  export TAILCALL_DOWNLOAD_URL=$(curl -s https://api.github.com/repos/tailcallhq/tailcall/releases/latest \
        | jq --raw-output --arg arch $(arch) '.assets | map(select(.name | (contains($arch) and endswith("musl")))) | first | .browser_download_url')
  wget -O /usr/local/bin/tailcall $TAILCALL_DOWNLOAD_URL
  chmod +x /usr/local/bin/tailcall
}

validate_tailcall_config() {
  setup_tailcall
  TC_TRACER=false tailcall check $TAILCALL_CONFIG
}

get_latest_version() {
  curl https://api.github.com/repos/$1/$2/releases/latest -s | jq .name -r
}

cp -r . /app
TC_CONFIG_DIR=/app
for val in $(echo $TAILCALL_CONFIG | tr '/' '\n'); do
  if [ "$val" = "." ]; then
    continue
  fi
  if [[ "$val" == *".graphql" || "$val" == *".json" || "$val" == *".yml" ]]; then
    TC_CONFIG_NAME=$val
    EXTENSION=$(echo $val | tr '.' '\n' | tail -n 1)
    break
  fi
done

mv "$TC_CONFIG_DIR/$TC_CONFIG_NAME" "$TC_CONFIG_DIR/config.$EXTENSION"
export TAILCALL_CONFIG=$TC_CONFIG_DIR
validate_tailcall_config
export TF_VAR_AWS_REGION=$AWS_REGION
export TF_VAR_AWS_IAM_ROLE=$AWS_IAM_ROLE
export TF_VAR_AWS_LAMBDA_FUNCTION_NAME=$AWS_LAMBDA_FUNCTION_NAME
export TF_VAR_AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export TF_VAR_AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export TF_VAR_TERRAFORM_ORG=$TERRAFORM_ORG
export TF_VAR_TERRAFORM_WORKSPACE=$TERRAFORM_WORKSPACE

export TF_TOKEN_app_terraform_io=$TERRAFORM_API_TOKEN

if [ "$TAILCALL_VERSION" = "latest" ]; then
  TAILCALL_VERSION=$(get_latest_version tailcallhq tailcall)
fi
export TF_VAR_TAILCALL_VERSION=$TAILCALL_VERSION


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

extract_urls() {
  grep -oE 'http[s]?://[^ "]+'
}

deploy() {
  if [ "$PROVIDER" = "aws" ]; then
    # todo: handle name collisions
    cp -r /aws /app
    setup_terraform
    awk -v org="\"$TERRAFORM_ORG\"" "{sub(/var.TERRAFORM_ORG/,org)}1" tailcall.tf > /tmp/temp1.tf
    awk -v workspace="\"$TERRAFORM_WORKSPACE\"" "{sub(/var.TERRAFORM_WORKSPACE/,workspace)}1" /tmp/temp1.tf > /tmp/temp2.tf
    mv /tmp/temp2.tf tailcall.tf
    terraform init
    terraform apply -auto-approve
  elif [ "$PROVIDER" = "fly" ]; then
    # todo: handle name collisions
    cp -r /fly /app
    setup_flyctl
    fly apps list | tail -n +2 | awk '{print $1}' | grep -w $FLY_APP_NAME > /dev/null && fly apps destroy $FLY_APP_NAME --auto-confirm
    flyctl launch --name $FLY_APP_NAME --region $FLY_REGION --local-only
  fi
}

deploy | tee /tmp/deployment.log

DEPLOYMENT_URL=$(cat /tmp/deployment.log | extract_urls | tail -n 1)
/scripts/health-check.sh "$DEPLOYMENT_URL"