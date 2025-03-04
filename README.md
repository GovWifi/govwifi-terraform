# Govwifi terraform

This repository contains instructions on how to build GovWifi end-to-end - the sites, services and infrastructure.

## Table of Contents

- [Overview](#overview)
- [Secrets](#secrets)
- [Running terraform for the first time](#running-terraform-for-the-first-time)
- [Running terraform](#running-terraform)
- [Bootstrapping terraform](#bootstrapping-terraform)
- [Rotating ELB Certificates](#rotating-ELB-certificates)

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

## Bootstrapping terraform

There are two methods available, the manual method and the bootstrap.sh script.

### Using the bootstrap.sh script

The script is located in govwifi-terraform directory.
It is called from the top level of this directory using:


```
scripts/bootstrap.sh [new environment name]
```
For example:
```
scripts/bootstrap.sh recovery
```

It can also be used with the 'tee' command to create a runfile preserving it's actions and outputs, e.g. name servers.


```
scripts/bootstrap.sh [new environment name] | tee [some file]
```
For example:
```
scripts/bootstrap.sh recovery | tee recovery.bootstrap
```


The script performs all the tasks starting from the section 'Bootstrapping terraform' upto and including the section 'Initialize The Backend'.

The manual steps to replicate the script functionality are below. If you used the script successfully, the next step is:

[Import S3 State bucket](#s3-state-bucket)




### Creating The Terraform For A Brand New GovWifi Environment
Follow the steps below to create a brand new GovWifi environment:

#### Duplicate & Rename All The Files Used For Our Staging Environment
Edit, then run the following command from the root of the govwifi-terraform directory to copy all the files you need for a new environment (replace `<NEW-ENV-NAME>` with the name of your new environment e.g. `foo`):


```
cp -Rp govwifi/staging govwifi/<NEW-ENV-NAME>

```

#### Change The Terraform Resource names
Edit then run the command below to update the terraform resource names (replace `<NEW-ENV-NAME>` with the name of your new environment e.g. `foo`):

```
for filename in ./govwifi/<NEW-ENV-NAME>/* ; do sed -i '' 's/staging/<NEW-ENV-NAME>/g' $filename ; done
```

#### Add The New Environment To The Makefile
Add the new environment to the Makefile. [See here for an example commit](https://github.com/GovWifi/govwifi-terraform/pull/777/commits/5482ac674b74b946b66040e158101bd4aa703a44#diff-76ed074a9305c04054cdebb9e9aad2d818052b07091de1f20cad0bbac34ffb52).

#### Update Application Environment Variables

The APP_ENV environment variable for any new GovWifi environment should be set to the name of your environment (e.g. `recovery`), unless this is a real disaster recovery of production (in which case set the APP_ENV to `production`).

#### Update Govwifi-Build

##### Add A Directory For Your New Environment
We keep sensitive (but non secret information) in a private repo called govwifi-build(https://github.com/GovWifi/govwifi-build). This folder is only accessible to GovWifi team members.  If you create a new GovWifi environment you will need to add new directory of the same name [here](https://github.com/GovWifi/govwifi-build/tree/master/non-encrypted/secrets-to-copy/govwifi).
Instructions
- Make a copy of the staging directory and rename it to your environment name

```
cp -Rp non-encrypted/secrets-to-copy/govwifi/staging non-encrypted/secrets-to-copy/govwifi/<NEW-ENV-NAME>
```

- Replace any references to `staging` in the newly created directory with your new environment name.
[See here for an example commit](https://github.com/GovWifi/govwifi-build/pull/541/files#diff-3382ad2da7f814e1bbd3a3ae321be41d7e23db80734611bb4ac90ab30d690cc5).

```
for filename in ./non-encrypted/secrets-to-copy/govwifi/<NEW-ENV-NAME>/* ; do sed -i '' 's/staging/<NEW-ENV-NAME>/g' $filename ; done
```

##### Add An SSH Key That Will Be Used By Your New Environment

- Generate an ssh keypair:

```
ssh-keygen -C "govwifi-developers@digital.cabinet-office.gov.uk"
```

Use the following format when prompted for the file name:

```
./govwifi-<NEW-ENV-NAME>-bastion-yyyymmdd
```

Use an empty passphrase.

- Add encrypted versions of the files to the govwifi-build/passwords/keys/ [using the instructions here](https://dev-docs.wifi.service.gov.uk/infrastructure/secrets.html#adding-editing-a-secret).
- Update the terraform for your environment:
  - With the name of the key in in the dublin-keys module in the dublin.tf file of your environment [See here for an example commit](https://github.com/GovWifi/govwifi-terraform/pull/777/commits/5482ac674b74b946b66040e158101bd4aa703a44#diff-9745914b44847dfa981046a838f8d8886ddf9454939ee465b8ea257950c5ca85R171).
  - With the **public** key file in the dublin-keys module in the dublin.tf file of your environment [See here for an example commit](https://github.com/GovWifi/govwifi-terraform/pull/777/commits/5482ac674b74b946b66040e158101bd4aa703a44#diff-9745914b44847dfa981046a838f8d8886ddf9454939ee465b8ea257950c5ca85R172).
  - Update name of key in dublin_backend module of dublin.tf, [see here for an example commit](https://github.com/GovWifi/govwifi-terraform/pull/777/commits/5482ac674b74b946b66040e158101bd4aa703a44#diff-9745914b44847dfa981046a838f8d8886ddf9454939ee465b8ea257950c5ca85R105).
  - With the name of the key in in the london-keys module in the london.tf file. To see an example [open the london.tf file in the commit](https://github.com/GovWifi/govwifi-terraform/pull/777/commits/5482ac674b74b946b66040e158101bd4aa703a44#diff-adf1083457d3aaad1753c8b333a2dbae1f1aff6f202d4b2390a983cef0389f88), click on the `Load diff` and navigate to a **line 24**.
  - With the **public** key file in the london-keys module in the london.tf file. To see an example [open the london.tf file in the commit](https://github.com/GovWifi/govwifi-terraform/pull/777/commits/5482ac674b74b946b66040e158101bd4aa703a44#diff-adf1083457d3aaad1753c8b333a2dbae1f1aff6f202d4b2390a983cef0389f88), click on the `Load diff` and navigate to a **line 25**.
  - To see an example [open the london.tf file in the commit](https://github.com/GovWifi/govwifi-terraform/pull/777/commits/5482ac674b74b946b66040e158101bd4aa703a44#diff-adf1083457d3aaad1753c8b333a2dbae1f1aff6f202d4b2390a983cef0389f88), click on the `Load diff` and navigate to a **line 55**.
  - Update the `ssh_key_name` variable in the variables.ft with the name of the ssh key [see here for an example commit](https://github.com/GovWifi/govwifi-terraform/pull/777/commits/5482ac674b74b946b66040e158101bd4aa703a44#diff-481c8f75e7c6c7ff9da71e734bc80ea24feff6f398f07b81ce8bd0439d9e8c8eR3)

### Prepare The AWS Environment
If you are running terraform in a brand new AWS account, then you will need to ensure the following steps have been completed before terraform will execute without error.

#### AWS Secret Manager
Ensure all required secrets have been entered into AWS Secrets manager in region eu-west-2 of your of your new account ([replicate over any secrets needed by resources in eu-west-1](https://docs.aws.amazon.com/secretsmanager/latest/userguide/create-manage-multi-region-secrets.html)). The name of the credentials in Secrets Manager MUST match the names of the secrets that already exist in the code.

##### Auto-generating the database secrets in a new AWS environment

The code will automatically generate RDS secrets for the admin, sessions and user databases. To allow this uncomment the blocks of code beginning with `COMMENT BELOW IN IF CREATING A NEW ENVIRONMENT FROM SCRATCH` and ending with `END CREATING A NEW ENVIRONMENT FROM SCRATCH` in the following files:
- govwifi-admin/secrets-manager.tf
- govwifi-backend/secrets-manager.tf

#### Increase The Default AWS Quotas
Terraform needs to create a larger number of resources than AWS allows out of the box. Luckily it is easy to get these limits increased.
- [Follow the instructions from AWS to request an increase](https://docs.aws.amazon.com/servicequotas/latest/userguide/request-quota-increase.html).
- Increase the quotas in your new account so they match the following
  - **22** Elastic IPs
  - **10** VPCs per Region

#### DNS Setup
- Create a hosted zone in your new environment in the following format `<ENV>.wifi.service.gov.uk` (for example `foobar.wifi.service.gov.uk` )

```
  gds aws <account-name> -- \
  aws route53 create-hosted-zone \
      --name "<ENV>.wifi.service.gov.uk" \
      --hosted-zone-config "Comment=\"\",PrivateZone=false" \
      --caller-reference "govwifi-$(date)"
```

- Copy the NS records for the newly created hosted zone.
- Log into the GovWifi Production AWS account `gds-cli aws govwifi -l`
- In the GovWifi Production account in the Route53 go to the `wifi.service.gov.uk` hosted zone.
- Add the NS records for your new environment with the copied NS records.
- Validate DNS delegation is complete:
  - Verify DNS delegation is complete ` dig -t NS <ENV>.wifi.service.gov.uk`  The result should match the your new environments NS records.

#### Create The Access Logs S3 Bucket

This holds information related to the terraform state, and must be created manually before the initial terraform run in a new environment. You will need to create two S3 buckets. One in eu-west-1 and one in eu-west-2. The bucket name must match this naming convention:

`govwifi-<ENV>-<AWS-REGION-NAME>-accesslogs`

An example commands for creating buckets in the Staging environment for the London and Dublin regions would be:

```
gds-cli aws govwifi-staging -- aws s3api create-bucket --bucket govwifi-staging-london-accesslogs --region eu-west-2 --create-bucket-configuration LocationConstraint=eu-west-2
```

```
gds-cli aws govwifi-staging -- aws s3api create-bucket --bucket govwifi-staging-dublin-accesslogs --region eu-west-1 --create-bucket-configuration LocationConstraint=eu-west-1
```

Use the following command to validate if the new buckets have been created:

```
gds-cli aws govwifi-<NEW-ENV-NAME> -- aws s3api list-buckets
```

### Setting Up Remote State
We use remote state, but there is a chicken and egg problem of creating a state bucket in which to store the remote state. When you are first creating a new environment (or migrating an environment not using remote state to use remote state) you will need to run the following commands. Anywhere you see the `<ENV>` replace this with the name of your environment e.g. `staging`.

#### Manually Create S3 State Bucket

```
gds-cli aws <account-name> -- aws s3api create-bucket --bucket govwifi-<ENV>-tfstate-eu-west-2 --region eu-west-2 --create-bucket-configuration LocationConstraint=eu-west-2
```
For example:

```
gds-cli aws govwifi-staging -- aws s3api create-bucket --bucket govwifi-staging-tfstate-eu-west-2 --region eu-west-2 --create-bucket-configuration LocationConstraint=eu-west-2
```

#### Initialize The Backend

```
gds-cli aws <account-name> -- make <ENV> init-backend
```

For example:

```
gds-cli aws govwifi-staging -- make staging init-backend
```
<a name="s3-state-bucket"></a>
#### Import S3 State bucket

```
gds-cli aws <account-name> -- make <ENV> terraform terraform_cmd="import module.tfstate.aws_s3_bucket.state_bucket govwifi-<env>-tfstate-eu-west-2"
```

Then comment out the lines related to replication configuration in govwifi-terraform/terraform-state/accesslogs.tf and govwifi-terraform/terraform-state/tfstate.tf.
```
replication_configuration{
  ....
}
```

The first time terraform is run in a new environment the replication configuration lines need to be commented out because the replication bucket in eu-west-1 will not yet exist. Leaving these lines uncommented will cause an error.

#### Plan and apply terraform

**NOTE:** Before running the command below you may need to edit the `Makefile` file and remove the `delete-secret` parameter from the `terraform` command.

Now run

```
gds-cli aws <account-name> -- make <ENV> plan
```

For example

```
gds-cli aws govwifi-development -- make alpaca plan
```

And then

```
gds-cli aws <account-name> -- make <ENV> apply
```

After you have finished terraforming follow the manual steps below to complete the setup.

**NOTE:** There is currently a bug within the AWS that means that terraform can get stuck on the "Creating" RDS instances step. While building the new Env in the Recovery account it took 30 minutes to create RDS instances. However, the User-DB's Read-Replica was not created during the first `terraform apply` run. Please run `terraform apply` once again. It may run for further 30 minutes. Validate the User-DB's Read-Replica status using the AWS Console.

#### Validate that all components are created.

Run the terraform `plan` and `apply` again. Ensure all components are create. Investigate further if required.

### Manual Steps Needed to Set Up a New Environment

#### Update AWS Secrets Manager entries for all RDS instances
When all RDS instances are created you need to use the AWS console to check configuration details of newly deployed instances. You need to use this information to update AWS Secrets for all databases' secrets. Following values need to be updated:
- rds/database_name/credentials/host
- rds/database_name/credentials/dbname
- rds/database_name/credentials/dbInstanceIdentifier

#### Add DKIM Authentication
Ensure you are in the eu-west-1 region (Ireland) and follow the instructions here(https://docs.aws.amazon.com/ses/latest/DeveloperGuide/send-email-authentication-dkim-easy-setup-domain.html) to verify your new subdomain (e.g. staging.wifi.service.gov.uk)

#### Activate SES Rulesets
The SES ruleset must be manually activated.
1. Login to the AWS console and ensure you are in the eu-west-1 region (Ireland).
1. Go to the SES section and select "Email receiving”.
1. Select  “GovWifiRuleSet” from the list
1. Select the "Set as active" button

#### Setting Up Deployment Pipelines For A New GovWifi Environment

Our deploy pipelines exist in a separate account. You can access it with the following command:

`gds-cli aws govwifi-tools -l`

In order to deploy applications you will need to create a new set of pipelines for that environment.
- There are set of template terraform files for creating pipelines for a new environment in govwifi-terraform/tools/pipeline-templates. You can copy these across manually and change the names or you can use the commands below. **All commands are run from the govwifi-terraform root directory**
- Copy the pipeline terraform template files in `govwifi-terraform/tools/pipeline-templates` to the govwifi-deploy directory:

```
for filename in tools/pipeline-templates/*your-env-name*;  do cp -Rp $filename ./govwifi-deploy/$(basename $filename) ; done
```

- Update the names of the terraform resources in the template files to match your new environment

```
for filename in ./govwifi-deploy/*your-env-name* ; do sed -i '' 's/your-env-name/<ENV_NAME>/g' $filename ; done
```

- Change the name of the file to match your new environment (change  **<NEW-ENV-NAME>** to your new environment name e.g. "dev")

```
for filename in ./govwifi-deploy/*your-env-name* ; do mv $filename ${filename/your-env-name/<NEW-ENV-NAME>}  ; done
```

There are 2 file to do this for.
To deploy the Codebuild and Code Pipeline the the new environment, replace "your-env-name" with your environment name, ensure the new account number is placed into the 'locals' file.

##### Updating Other Pipeline files:

You will also need to do the following in the tools account:

- Add the new environment's account number to AWS Secrets Manager, and then add it to terraform, [see here for an example](https://github.com/GovWifi/govwifi-terraform/pull/777/commits/5482ac674b74b946b66040e158101bd4aa703a44#diff-d94ff418330c275e25ef2b45b9d7d2dd4a9ef3720db62dd38073bd72773562d4).
- Add your new AWS account ID as a local variable in the govwifi-deploy module, [see here for an example](https://github.com/GovWifi/govwifi-terraform/pull/777/commits/5482ac674b74b946b66040e158101bd4aa703a44#diff-80629d600c5574b9e7d4dc7ba991ce39068d32cabd1046130d5e8e4827460f77).
- An ECR repository for your new environment,  [see here for an example](https://github.com/GovWifi/govwifi-terraform/pull/777/commits/5482ac674b74b946b66040e158101bd4aa703a44#diff-62eed9657e3fa19b6a5801b47b549ab70711b54c5997c50fb90a395653cccf9d).
- Give the GovWifi Tools account permission to deploy things in your new environment
  - Add appropriate S3 access: [see here for an example](https://github.com/GovWifi/govwifi-terraform/pull/777/commits/5482ac674b74b946b66040e158101bd4aa703a44#diff-d94ff418330c275e25ef2b45b9d7d2dd4a9ef3720db62dd38073bd72773562d4).
  - Add appropriate codepipeline permissions [see here for an example](https://github.com/GovWifi/govwifi-terraform/pull/777/commits/5482ac674b74b946b66040e158101bd4aa703a44#diff-02cf364873b2fce26391e6e2b6d9ed222ce8e8f23f7d745e5c8024b02a932389).
  - Allow your new environment to access the KMS keys used by Codepipeline [see here for an example](https://github.com/GovWifi/govwifi-terraform/pull/777/commits/5482ac674b74b946b66040e158101bd4aa703a44#diff-8a01e39d3fd4d4d2ee124f9f0c45495bb36677f5384040c59ff023b3f517032d).

#### Restoring The Databases

**NOTE:**
- In a BCP scenario for the Production environment change the Bastion instance type to `m4.xlarge` and allocate `100GB` of `gp3` storage with `12000IOPS` and `500mbps` provisioned. You can complete this via the AWS Console. You need to make all the storage changes at the same time, otherwise, you will get a notification that further changes can be done in 6 hours.

  More info about expanding Linux storage [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/recognize-expanded-volume-linux.html).

  Remember to complete the volume size expansion on the Bastion level as well. SSH to the Bastion and run the following commands:
```
	lsblk
	sudo growpart /dev/xvda 1
	sudo resize2fs /dev/xvda1
```

- If you are attempting to recover the production environment change the RDS instance type for the `session` database to the `m4.xlarge` and allocate `400GB` of `gp3` storage which gives you `12000IOPS` and `500mbps`. You may need to consider disabling the Multi-AZ setup while restoring data.

- For an environment other than the Production ensure RDS database names are:
  - For the Users Database is set as `govwifi_<ENV>_users`
  - For the Session Database is set as `govwifi_<ENV>`
  - For the Admin Database is set as `govwifi_admin_staging`

- If you are setting up a new environment and the `app_env` variable has been set to `staging` then copy the databases from the pre-existing staging environment and leave any references to `staging` in the database names unchanged. For example the user database name would be left as `govwifi_staging_users`. The `app_env` value in terraform MUST match the database environment reference otherwise the GovWifi applications will fail to start.

[Follow thees instructions to restore the databases](https://dev-docs.wifi.service.gov.uk/infrastructure/database-restore.html#restoring-databases).

---
## Application deployment

### Deploy terraform to the Tools account

Run the following commands to initialize terraform for GovWifi-Tools account:

`gds aws govwifi-tools -- make govwifi-tools run-terraform-init`

Run the terraform plan:

`gds aws govwifi-tools -- make govwifi-tools plan`

**Note:** You may receive the "Warning: Provider aws.dublin is undefined", this is expected.

Run the terraform apply:

`gds aws govwifi-tools -- make govwifi-tools apply`

**Note:** If you receive an error, try to run the apply command once again.

### Running CI/CD pipelines for the first time

Login to the `GovWifi-Tools` account using the AWS Console:

`gds-cli aws govwifi-tools -l`

Run the AWS CodeBuild's Build Projects created for the new environment (e.g. admin-push-image-to-ecr-<ENV>). These will add the docker images to the appropriate ECR repositories.

[Follow these deployment instructions](https://dev-docs.wifi.service.gov.uk/applications/deploying.html#core-services), refer to the document linked within the `Core services` section for detailed steps.

## Updating task definitions

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

## Connecting Notify To Your New GovWifi Environment

[Detailed documentation on setting up Notify with GovWifi can be found in this google doc](https://docs.google.com/document/d/1fgCjuvmfEiVRCYdxGo7nYShI5sQZsLZqssate0Hdu6U/edit?pli=1#heading=h.jj72y88glvis) (you will need to be a member of the GovWifi Team to view it).

---

## Rotating ELB Certificates

To rotate the ELB ACM certificates, you need to create a new certificate in the
aws console, with the domain name required, or by running the following from the
cli

```
AWS_DEFAULT_REGION=<region> aws acm request-certificate --domain-name <domain-name> --domain-validation-options DomainName=<domain-name>,ValidationDomain=<validation-domain>
```

Where validation-domain is wifi.service.gov.uk for prod, and wifi.staging.service.gov.uk for staging

Once this is created, you will need to validate the domain. There is some logic
to listen to emails on the required domain and copy them to an s3 bucket in the
govwifi-terraform repo. You can look in the `<ENV>-admin-emailbucket` to find
this - it will likely be the last modified file. You can also use the CLI

```
aws s3 ls s3://<ENV>-admin-emailbucket/
aws s3 cp s3://<ENV>-admin-emailbucket/<filename-of-last-modified-file> -
```

Find the validation link and load it in a browser

You can then update the `elb-ssl-cert-arn` secret value in the terraform secrets
file for the environment to be updated to be the arn of your newly requested
certificate, and apply terraform

Once you have applied terraform, you should clean up the unused certificates in
the console

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
