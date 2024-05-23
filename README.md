# gh-action

A GitHub Action for deploying a [tailcall](https://tailcall.run) instance on AWS Lambda, using terraform.

### Inputs

| Name                       | Type       | Description                                                                                                      |
|----------------------------|------------|------------------------------------------------------------------------------------------------------------------|
| `tailcall-config`          | `Required` | The `tailcall` config that needs to be deployed.                                                                 |
| `tailcall-version`         | `Optional` | The version of `tailcall` to use for deployment. Defaults to the latest version if unspecified.                  |
| `aws-access-key-id`        | `Required` | AWS access key.                                                                                        |
| `aws-secret-access-key`    | `Required` | AWS secret access key.                                                                                 |
| `aws-region`               | `Required` | AWS region.                                                                                         |
| `aws-iam-role`             | `Optional` | The name of the IAM role that will be created for the deployment. Defaults to `iam_for_tailcall` if unspecified. |
| `aws-lambda-function-name` | `Optional` | The name of the lambda function that will be created. Defaults to `tailcall` if unspecified.                     |

## Example

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
        uses: tailcallhq/gh-action@a629949cab3e55b0f3a3989fc3bcdd9a7ac3a482
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: 'us-east-1'
          aws-iam-role: 'iam_for_tailcall'
          tailcall-config: 'config.graphql'
```