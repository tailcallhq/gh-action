# gh-action

A GitHub Action for deploying a [tailcall](https://tailcall.run) server on AWS Lambda or [Fly.io](https://fly.io).

### Inputs

| Name                       | Description                                                                                                                       |
|----------------------------|-----------------------------------------------------------------------------------------------------------------------------------|
| `provider`                 | The provider to use for deployment. Currently, only `aws` and `fly` are supported.                                                |
| `tailcall-config`          | The path to the `tailcall` configuration file used for deployment. This file defines the server's setup and behavior.             |
| `tailcall-version`         | Specifies the version of `tailcall` to use for deployment. If not provided, the Action defaults to the latest available version.  |
| `aws-access-key-id`        | The AWS access key ID required for authentication. Ensure this value is stored securely, such as in GitHub Secrets.               |
| `aws-secret-access-key`    | The AWS secret access key required for authentication. Store this securely, such as in GitHub Secrets.                            |
| `aws-region`               | The AWS region where the Lambda function will be deployed (e.g., `us-east-1`).                                                    |
| `aws-iam-role`             | The IAM role name to be created and used for the deployment. If not specified, defaults to `iam_for_tailcall`.                    |
| `aws-lambda-function-name` | The name assigned to the created Lambda function. Defaults to `tailcall` if not specified.                                        |
| `terraform-api-token`      | The Terraform Cloud API token required for authentication. Ensure this value is stored securely, such as in GitHub Secrets.       |
| `fly-api-token`            | The Fly API token required for authentication. Ensure this value is stored securely, such as in GitHub Secrets.                   |
| `fly-app-name`             | The name of the Fly app to deploy the server to. Defaults to `tailcall` if not specified.                                         |

## Examples

### Deploying a Tailcall server on AWS Lambda

```yaml
on: [push]

jobs:
  deploy_tailcall:
    runs-on: ubuntu-latest
    name: Deploy Tailcall
    steps:
      - name: Checkout repository
        uses: actions/checkout@v2
      - name: Deploy Tailcall
        id: deploy-tailcall
        uses: tailcallhq/gh-action@v0.2
        with:
          provider: 'aws'
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }} 
          aws-region: "us-east-1"
          aws-iam-role: "iam_for_tailcall"
          terraform-api-token: ${{ secrets.TERRAFORM_API_TOKEN }}
          tailcall-config: 'config.graphql'
```

### Deploying a Tailcall server on Fly.io

```yaml
on: [push]

jobs:
  deploy_tailcall:
    runs-on: ubuntu-latest
    name: Deploy Tailcall
    steps:
      - name: Checkout repository
        uses: actions/checkout@v2
      - name: Deploy Tailcall
        id: deploy-tailcall
        uses: tailcallhq/gh-action@v0.2
        with:
          provider: 'fly'
          fly-api-token: ${{ secrets.FLY_API_TOKEN }} 
          fly-app-name: "tailcall"
          tailcall-config: 'config.graphql'
```