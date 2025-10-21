# Docker/K8s Playground
This is a repo that can set up a Docker and Kubernetes playgroud with
access to an AWS account.

## IMPORTANT NOTE
- The resources provisioned cost money. This works well with access to a service like Pluralsight's AWS Cloud Playground

## Requirements
- Access to an AWS account 
- An SSH client
- Terraform

## Setting up the Environment
To set up the environment:
1. Run `aws configure` to run set up the access keys and regions.
2. Run the `start.sh` script and wait to configure.
3. (Optional): If you want to connect to the playground run `connect.sh`.
This is done automatically, but can also be done manually

## Troubleshooting
- If you connect to the provisioned playground and certain commands like `docker` or `kubectl` are not working, try disconnecting from the instance, waiting a bit, then reconnecting.
