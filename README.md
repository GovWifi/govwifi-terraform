# Govwifi terraform

This repository contains instructions on how to build GovWifi end-to-end - the sites, services and infrastructure.

## Table of Contents

- [Overview](#overview)
- [Secrets](#secrets)
- [Running terraform for the first time](#running-terraform-for-the-first-time)
- [Running terraform](#running-terraform)
- <a href="/README-new-environment.md">Creating a new GovWifi Environment</a>

## Overview
Our public-facing websites are:
- A [product page](https://github.com/GovWifi/govwifi-product-page) explaining the benefits of GovWifi
- An [admin platform](https://github.com/GovWifi/govwifi-admin) for organisations to self-serve changes to their GovWifi installation
- [Technical documentation](https://github.com/GovWifi/govwifi-tech-docs), explaining GovWifi in more detail to clients and organisations. Aimed at network administrators

Our services include:
- [Frontend servers](https://github.com/GovWifi/govwifi-frontend), instances of FreeRADIUS that act as authentication servers and use [FreeRADIUS Prometheus Exporter](https://github.com/bvantagelimited/freeradius_exporter) to measure server stats
- An [authentication API](https://github.com/GovWifi/govwifi-authentication-api), which the frontend calls to help authenticate GovWifi requests
- A [logging API](https://github.com/GovWifi/govwifi-logging-api), which the frontend calls to record each GovWifi request
- A [user signup API](https://github.com/GovWifi/govwifi-user-signup-api), which handles incoming sign-up texts and e-mails (with a little help from AWS)
- A Prometheus server to scrape metrics from the FreeRADIUS Prometheus Exporters which exposes FreeRADIUS server data

We manage our infrastructure via:
- Terraform, split across this repository and [govwifi-build](https://github.com/GovWifi/govwifi-build)
- The [safe restarter](https://github.com/GovWifi/govwifi-safe-restarter), which uses a [CanaryRelease](https://martinfowler.com/bliki/CanaryRelease.html) strategy to increase the stability of the frontends

Other repositories:
- [Acceptance tests](https://github.com/GovWifi/govwifi-acceptance-tests), which pulls together GovWifi end-to-end, from the various repositories, and runs tests against it.

## Secrets

Secret credentials are stored in AWS Secrets Manager in the format of `<service>/<item>` (`<item>` must be hyphenated not underscored).

`service` will be the GovWifi service (admin, radius, user-signup, logging) related to that secret. If the secret is not specific to a GovWifi service, use the AWS service or product it relates to (e.g., rds, s3, grafana).

For historical use of secrets  please see: [GovWifi build](https://github.com/GovWifi/govwifi-build). This is now used to store non secret but sensitive information such as IP ranges.

## Running terraform for the first time

Initialize terraform if running for the first time:

```
gds-cli aws <account-name> -- make <ENV> init-backend
gds-cli aws <account-name> -- make <ENV> plan
```

Example ENVs are: `wifi`, `wifi-london` and `staging`.

## Running terraform

```
gds-cli aws <account-name> -- make <ENV> plan
gds-cli aws <account-name> -- make <ENV> apply
```

### Running terraform target

Terraform allows for ["resource targeting"](https://www.terraform.io/docs/cli/commands/plan.html#resource-targeting), or running `plan`/`apply` on specific modules.

We've incorporated this functionality into our `make` commands. **Note**: this should only be done in exceptional circumstances.

To retrieve a module name, run a `terraform plan` and copy the module name (EXCLUDING "module.") from the Terraform output:

```bash
$ gds-cli aws <account-name> -- make staging plan
...

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  ~ update in-place

Terraform will perform the following actions:

  # module.api.aws_iam_role_policy.some_policy  <-- module name
...
```

In this case, the module name would be `api.aws_iam_role_policy.some_policy`

To `plan`/`apply` a specific resource use the standard `make <ENV> plan | apply` followed by a space separated list of one or more modules:

```
$ gds-cli aws <account-name> -- make <ENV> plan modules="backend.some.resource api.some.resource"
$ gds-cli aws <account-name> -- make <ENV> apply modules="frontend.some.resource"
```

If combining other Terraform commands (e.g., `-var` or `-replace`) with targeting a resource, use the `terraform_target` command:

```bash
$ gds-cli aws <account-name> -- make <ENV> terraform_target terraform_cmd="<plan | apply> -replace <your command>"
```

#### Deriving module names

You can also derive the `module` by combining elements from the module declaration, the AWS resource type, and the resource name.

Module names are made up of four main parts: `module` (default AWS naming convention), `module name` (found in `govwifi/*/main.tf` files), the AWS resource type, and the AWS resource name.

Modules are declared in `main.tf`, like this example from `govwifi/staging/main.tf`:

```text
module "backend" {
    // A bunch of variables being set
}
```

For example, to derive the bastion instance module name:

1. Find where the instance resource is declared (in this case `govwifi-backend/management.tf`).
2. Note the resource type for that component (`aws_instance`) and the resource name (`management`) in `govwifi-backend/management.tf`.
3. Find where the module is declared in `govwifi/*/main.tf`; typically the module name matches the name of the directory where the resource is declared minus the `govwifi` prefix. So for `govwifi-backend`, there's a module declaration for `backend` in each of the `main.tf` files in `govwifi/*`.
4. Build the `module` using the components: `module`, `backend`, `aws_instance`, `management`.

It should look like this, `module.backend.aws_instance.management`:

| AWS default | module declaration name | AWS resource type | AWS resource name |
| :----: | :----: | :----: | :----: |
| module  | backend | aws_instance | management |

---

## Updating Pipelines

This affects the following apps:
- [admin](https://github.com/GovWifi/govwifi-admin)
- [authentication-api](https://github.com/GovWifi/govwifi-authentication-api)
- [user-api](https://github.com/GovWifi/govwifi-user-signup-api)
- [logging-api](https://github.com/GovWifi/govwifi-logging-api)

Once the task definitions for the above apps have been created by terraform, they are then managed by Codepipeline.  When the pipelines run for the first time after their initial creation, they store a copy of the task definition for that application in memory. If you create a new version of a task definition, **Codepipeline will still use the previous one AND CONTINUE to deploy the old one**. To get Codepipeline to use new task definitions you need to recreate the  pipelines. This is a flaw on AWS's part. Instructions for a work around are below:

- First apply your task definition change.
- Remove the "ignore_task" attribute for the service you are modifying. For example if you were changing the admin task [you would remove the task_definition element in this array](https://github.com/GovWifi/govwifi-terraform/blob/5482ac674b74b946b66040e158101bd4aa703a44/govwifi-admin/cluster.tf#L207). For example change the line so it reads `ignore_changes = [tags_all, task_definition]`)
- Using terraform destroy pipeline for the particular application you are changing the task definition for. For example, if you were changing the task definition for the admin pipeline, [comment out this entire file](https://github.com/GovWifi/govwifi-terraform/blob/5482ac674b74b946b66040e158101bd4aa703a44/govwifi-deploy/alpaca-codepipeline-admin.tf).
  - Run terraform the govwifi tools account with `gds-cli aws govwifi-tools -- make govwifi-tools apply`
- Recreate the pipeline  using terraform
  - Uncomment previously commented lines
    - Run terraform in tools again
    - Warning: The pipelines will run as soon as they are created. But will not deploy to production without manual approval. [See the pipeline documentation for more information](https://docs.google.com/document/d/1ORrF2HwrqUu3tPswSlB0Duvbi3YHzvESwOqEY9-w6IQ/edit#heading=h.j6kp1kgy7mfw).
  - The new task definition should now be picked up.

---

## How to contribute

1. Create a feature or fix branch
2. Make your changes
3. Run `make format` to format Terraform code
4. Raise a pull request

### Style guide

Terraform's formatting tool takes care of much of the style, but there are some additional points.

#### Naming

When naming resources, data sources, variables, locals and outputs, only use underscores to separate words. For example:

```terraform
resource "aws_iam_user_policy" "backup_s3_read_buckets" {
  ...
```

#### Trailing newlines

All lines in a file should end in a terminating newline character, including the last line. This helps to avoid unnecessary diff noise where this newline is added after a file has been created.

## License

This codebase is released under [the MIT License][mit].

[mit]: LICENSE
