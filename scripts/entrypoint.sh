#!/bin/sh -l

set -e

setup_tailcall() {
  export TAILCALL_DOWNLOAD_URL=$(curl -s https://api.github.com/repos/tailcallhq/tailcall/releases/latest \
        | jq --raw-output --arg arch $(arch) '.assets | map(select(.name | (contains($arch) and endswith("musl")))) | first | .browser_download_url')
  wget -O /usr/local/bin/tailcall $TAILCALL_DOWNLOAD_URL
  chmod +x /usr/local/bin/tailcall
}

validate_tailcall_config() {
  setup_tailcall
  echo "TAILCALL_CONFIG: $TAILCALL_CONFIG"
  TC_TRACER=false tailcall check $TAILCALL_CONFIG
}

get_latest_version() {
  curl https://api.github.com/repos/$1/$2/releases/latest -s | jq .name -r
}

echo "DIRS: $(ls)"
mkdir -p /app
cp -r ./* /app
TC_CONFIG_DIR_ROOT=/app
TC_CONFIG_DIR=$(dirname $TAILCALL_CONFIG | sed 's|^\./||')
echo $TC_CONFIG_DIR
TC_CONFIG_NAME=$(basename $TAILCALL_CONFIG)
EXTENSION=$(echo $TC_CONFIG_NAME | tr '.' '\n' | tail -n 1)

mv "$TC_CONFIG_DIR_ROOT/$TC_CONFIG_DIR/$TC_CONFIG_NAME" "$TC_CONFIG_DIR_ROOT/$TC_CONFIG_DIR/config.$EXTENSION"
export TAILCALL_CONFIG="$TC_CONFIG_DIR_ROOT/$TC_CONFIG_DIR/config.$EXTENSION"
export TC_RELATIVE_PATH="$TC_CONFIG_DIR/config.$EXTENSION"
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

create_fly_toml() {
  touch fly.toml
  toml set --toml-path fly.toml app $FLY_APP_NAME
  toml set --toml-path fly.toml primary_region $FLY_REGION
  toml add_section --toml-path fly.toml http_service
  export PORT=$(rg -o '@server\([^)]*port:\s*(\d+)[^)]*\)' --replace '$1' $TAILCALL_CONFIG || echo 8080)
  echo "PORT: $PORT"
  toml set --toml-path fly.toml http_service.internal_port $PORT --to-int
  cat fly.toml
}

deploy() {
  if [ "$PROVIDER" = "aws" ]; then
    # todo: handle name collisions
    mkdir -p /aws/config
    cp -r /app/* /aws/config
    cd /aws
    echo "List: $(find /app -type f)"
    /scripts/create-tf-zip.sh
    echo "List: $(find /app -type f)"
    setup_terraform
    BOOTSTRAP_PATH="config/$TC_CONFIG_DIR/bootstrap"
    echo "BOOTSTRAP_PATH: $BOOTSTRAP_PATH"
    awk -v org="\"$TERRAFORM_ORG\"" "{sub(/var.TERRAFORM_ORG/,org)}1" /aws/tailcall.tf > /tmp/temp1.tf
    awk -v workspace="\"$TERRAFORM_WORKSPACE\"" "{sub(/var.TERRAFORM_WORKSPACE/,workspace)}1" /tmp/temp1.tf > /tmp/temp2.tf
    awk -v boot_strap_path="$BOOTSTRAP_PATH" "{sub(/BOOTSTRAP_PATH/,workspace)}1" /tmp/temp2.tf > /tmp/temp3.tf
    mv /tmp/temp3.tf tailcall.tf
    echo "config: $(cat tailcall.tf)"
    terraform init
    echo "List: $(find /app -type f)"
    TF_LOG=DEBUG terraform apply -auto-approve
  elif [ "$PROVIDER" = "fly" ]; then
    # todo: handle name collisions
    cp -r /app/* /fly
    awk -v config_path="$TC_RELATIVE_PATH" "{sub(/TC_CONFIG_PATH/,config_path)}1" /extras/config.json > /fly/config.json
    cat /fly/config.json
    setup_flyctl
    cd /fly
    export FLY_APP_NAME="$(echo $FLY_APP_NAME | tr '_' '-')"
    fly apps list | tail -n +2 | awk '{print $1}' | grep -w tailcall > /dev/null && fly apps destroy $FLY_APP_NAME --auto-confirm || echo "App not found"
    create_fly_toml
    flyctl launch --local-only --copy-config
  fi
}

deploy | tee /tmp/deployment.log

DEPLOYMENT_URL=$(cat /tmp/deployment.log | extract_urls | tail -n 1)
/scripts/health-check.sh "$DEPLOYMENT_URL"