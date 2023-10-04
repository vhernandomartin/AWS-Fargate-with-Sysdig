# AWS-Fargate-with-Sysdig

## Fargate bundle

This repo contains a terraform bundle to deploy a demo environment in a AWS infrastructure with AWS ECS and AWS Fargate.

## Usage

### Variables

A few variables need to be defined prior to running both `terraform init` and `terraform apply`commands.
Please check the following table as a reference.

| Variable name     | Description | Sample |
|-------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------|
| DEMO_ENV_PREFIX   | An identifier to be used as a prefix for your AWS infrastructure                                                                                                                            | victor-fg                            |
| AWS_REGION        | The AWS Region where AWS infrastructure will be deployed                                                                                                                                    | eu-west-1                            |
| AGENT_ACCESS_KEY  | The Sysdig Agent Key. Check [Sysdig documentation](https://docs.sysdig.com/en/docs/administration/administration-settings/agent-access-keys/) if you want to learn more                     | aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee |
| AGENT_COLLECTOR   | The Sysdig Agent collector host, it must be set the one based on your SaaS region. Check [Sysdig documentation](https://docs.sysdig.com/en/docs/administration/saas-regions-and-ip-ranges/) | ingest-eu1.app.sysdig.com            |
| AGENT_PORT        | The Sysdig Agent collector port                                                                                                                                                             | 6443                                 |
| SECURE_API_TOKEN  | The Sysdig API token that enable users to communicate with the Sysdig API                                                                                                                   | vvvvvvvv-wwww-xxxx-yyyy-zzzzzzzzzzzz |

### Deploying the environment

First off, as discussed earlier, export the required variables using your own values.
```
$ export DEMO_ENV_PREFIX=victor-fg
$ export AWS_REGION=eu-west-1
$ export AGENT_ACCESS_KEY=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee
$ export AGENT_COLLECTOR=ingest-eu1.app.sysdig.com
$ export AGENT_PORT=6443
$ export SECURE_API_TOKEN=vvvvvvvv-wwww-xxxx-yyyy-zzzzzzzzzzzz
```

Following, run terraform to start deploying the AWS infrastructure.
```
$ terraform init && terraform apply \ 
  -var "prefix=$DEMO_ENV_PREFIX" \
  -var="region=$AWS_REGION" \
  -var="access_key=$AGENT_ACCESS_KEY" \
  -var="collector_host=$AGENT_COLLECTOR" \
  -var="collector_port=$AGENT_PORT" \
  -var="secure_api_token=$SECURE_API_TOKEN"
```

### Tearing down the environment

If you want to get rid of the AWS environment run terraform destroy with the same variables used at deployment time.
```
$ terraform destroy \
  -var "prefix=$DEMO_ENV_PREFIX" \
  -var="region=$AWS_REGION" \
  -var="access_key=$AGENT_ACCESS_KEY" \
  -var="collector_host=$AGENT_COLLECTOR" \
  -var="collector_port=$AGENT_PORT" \
  -var="secure_api_token=$SECURE_API_TOKEN"
```