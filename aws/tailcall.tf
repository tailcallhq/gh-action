terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.62.0"
    }
    github = {
      source  = "integrations/github"
      version = "6.0.0-beta"
    }
  }

  cloud {
    organization = var.TERRAFORM_ORG

    workspaces {
      name = var.TERRAFORM_WORKSPACE
    }
  }
}

variable "AWS_REGION" {
  type = string
}

variable "AWS_IAM_ROLE" {
  type = string
}

variable "AWS_ACCESS_KEY_ID" {
  type = string
}

variable "AWS_SECRET_ACCESS_KEY" {
  type = string
}

variable "AWS_LAMBDA_FUNCTION_NAME" {
  type = string
}

variable "TAILCALL_VERSION" {
  type = string
}

variable "TERRAFORM_ORG" {
    type = string
}

variable "TERRAFORM_WORKSPACE" {
    type = string
}

variable "TAILCALL_PATH" {
  type = string
}

provider "aws" {
  region = var.AWS_REGION
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_tailcall" {
  name               = var.AWS_IAM_ROLE
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

provider "github" {}

data "github_release" "tailcall" {
  owner       = "tailcallhq"
  repository  = "tailcall"
  retrieve_by = "tag"
  release_tag = var.TAILCALL_VERSION
}

data "http" "bootstrap" {
  url = data.github_release.tailcall.assets[index(data.github_release.tailcall.assets.*.name, "tailcall-aws-lambda-bootstrap")].browser_download_url
}

resource "local_sensitive_file" "bootstrap" {
  content_base64 = filebase64("bootstrap")
  filename = "config/bootstrap"
}

resource "local_sensitive_file" "tailcall" {
  content_base64 = data.http.bootstrap.response_body_base64
  filename       = var.TAILCALL_PATH
}

resource "local_sensitive_file" "config" {
  for_each = fileset(path.module, "config/**")
  content_base64 = filebase64("${each.key}")
  filename       = "${each.key}"
}

data "archive_file" "tailcall" {
  type = "zip"
  depends_on = [
    local_sensitive_file.bootstrap,
    local_sensitive_file.config,
    local_sensitive_file.tailcall
  ]
  source_dir = "config"
  output_path = "tailcall.zip"
}

resource "aws_lambda_function" "tailcall" {
  depends_on = [
    data.archive_file.tailcall
  ]

  role             = aws_iam_role.iam_for_tailcall.arn
  function_name    = var.AWS_LAMBDA_FUNCTION_NAME
  runtime          = "provided.al2"
  architectures    = ["x86_64"]
  handler          = "start"
  filename         = data.archive_file.tailcall.output_path
  source_code_hash = data.archive_file.tailcall.output_base64sha256
}

resource "aws_api_gateway_rest_api" "tailcall" {
  name = "tailcall"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.tailcall.id
  parent_id   = aws_api_gateway_rest_api.tailcall.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id      = aws_api_gateway_rest_api.tailcall.id
  resource_id      = aws_api_gateway_resource.proxy.id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.tailcall.id
  resource_id             = aws_api_gateway_method.proxy.resource_id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.tailcall.invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id      = aws_api_gateway_rest_api.tailcall.id
  resource_id      = aws_api_gateway_rest_api.tailcall.root_resource_id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id             = aws_api_gateway_rest_api.tailcall.id
  resource_id             = aws_api_gateway_method.proxy_root.resource_id
  http_method             = aws_api_gateway_method.proxy_root.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.tailcall.invoke_arn
}

resource "aws_api_gateway_deployment" "tailcall" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.tailcall.id
}

resource "aws_api_gateway_stage" "live" {
  deployment_id = aws_api_gateway_deployment.tailcall.id
  rest_api_id   = aws_api_gateway_rest_api.tailcall.id
  stage_name    = "live"
}

resource "aws_api_gateway_method_settings" "live" {
  rest_api_id = aws_api_gateway_rest_api.tailcall.id
  stage_name  = aws_api_gateway_stage.live.stage_name
  method_path = "*/*"

  settings {}
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tailcall.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.tailcall.execution_arn}/*/*"
}

output "graphql_url" {
  value = "${aws_api_gateway_stage.live.invoke_url}/graphql"
}
