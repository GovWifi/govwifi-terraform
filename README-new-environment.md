# Creating a new GovWifi environment

Follow the steps below to create a brand new GovWifi environment:

#### Duplicate & Rename All The Files Copied From The Staging Environment
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

You will need to raise a PR and merge your change to the new environment to `master` before continuing.

##### Add An SSH Key That Will Be Used By Your New Environment

- Generate an ssh keypair:

```
ssh-keygen -t rsa -b 4096 -C "govwifi-developers@digital.cabinet-office.gov.uk"
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

#### Increase The Default AWS Quotas If Needed
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

An example command for creating buckets in the Development environment for the London and Dublin regions would be:

```
gds-cli aws govwifi-development -- aws s3api create-bucket --bucket govwifi-development-london-accesslogs --region eu-west-2 --create-bucket-configuration LocationConstraint=eu-west-2
```

```
gds-cli aws govwifi-development -- aws s3api create-bucket --bucket govwifi-development-dublin-accesslogs --region eu-west-1 --create-bucket-configuration LocationConstraint=eu-west-1
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
gds-cli aws govwifi-development -- aws s3api create-bucket --bucket govwifi-development-tfstate-eu-west-2 --region eu-west-2 --create-bucket-configuration LocationConstraint=eu-west-2
```

#### Initialize The Backend

```
gds-cli aws <account-name> -- make <ENV> init-backend
```

For example:

```
gds-cli aws govwifi-development -- make development init-backend
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
gds-cli aws govwifi-development -- make development plan
```

And then

```
gds-cli aws <account-name> -- make <ENV> apply
```

After you have finished terraforming follow the manual steps below to complete the setup.

**NOTE:** There is currently a bug within the AWS that means that terraform can get stuck on the "Creating" RDS instances step. While building the new Env in the Recovery account it took 30 minutes to create RDS instances. However, the User-DB's Read-Replica was not created during the first `terraform apply` run. Please run `terraform apply` once again. It may run for further 30 minutes. Validate the User-DB's Read-Replica status using the AWS Console.

#### Validate that all components are created.

Run the terraform `plan` and `apply` again. Ensure all components are create. Investigate further if required.

### Additional Manual Steps Needed to Set Up a New Environment

#### Update AWS Secrets Manager entries for all RDS instances
When all RDS instances are created you need to use the AWS console to check configuration details of newly deployed instances. You need to use this information to update AWS Secrets for all databases' secrets. Following values need to be updated:
- rds/database_name/credentials/host
- rds/database_name/credentials/dbname
- rds/database_name/credentials/dbInstanceIdentifier

#### Add DKIM Authentication
Ensure you are in the eu-west-1 region (Ireland) and follow the instructions here(https://docs.aws.amazon.com/ses/latest/DeveloperGuide/send-email-authentication-dkim-easy-setup-domain.html) to verify your new subdomain (e.g. development.wifi.service.gov.uk)

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
To deploy the Codebuild and Codepipeline the the new environment, replace "your-env-name" with your environment name, ensure the new account number is placed into the 'locals' file.

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

Follow the instructions in the team [manual](https://dev-docs.wifi.service.gov.uk/infrastructure/database-restore.html#restoring-databases) to restore the databases.

- For an environment other than the Production ensure RDS database names are:
  - For the Users Database is set as `govwifi_<ENV>_users`
  - For the Session Database is set as `govwifi_<ENV>`
  - For the Admin Database is set as `govwifi_admin_<ENV>`

- The `app_env` value in terraform MUST match the database environment reference otherwise the GovWifi applications will fail to start.

**NOTE (ignore unless in a REAL BCP scenario ):**
- In a BCP scenario for the Production environment change the Bastion instance type to `m4.xlarge` and allocate `100GB` of `gp3` storage with `12000IOPS` and `500mbps` provisioned. You can complete this via the AWS Console. You need to make all the storage changes at the same time, otherwise, you will get a notification that further changes can be done in 6 hours.

  More info about expanding Linux storage [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/recognize-expanded-volume-linux.html).

  Remember to complete the volume size expansion on the Bastion level as well. SSH to the Bastion and run the following commands:

```
    lsblk
    sudo growpart /dev/xvda 1
    sudo resize2fs /dev/xvda1
```

- If you are attempting to recover the production environment change the RDS instance type for the `session` database to the `m4.xlarge` and allocate `400GB` of `gp3` storage which gives you `12000IOPS` and `500mbps`. You may need to consider disabling the Multi-AZ setup while restoring data.

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

If you need to <a href="README.md#updating-pipelines">update the pipelines after creating them please see these instructions</a>

## Connecting Notify To Your New GovWifi Environment

[Detailed documentation on setting up Notify with GovWifi can be found in this google doc](https://docs.google.com/document/d/1fgCjuvmfEiVRCYdxGo7nYShI5sQZsLZqssate0Hdu6U/edit?pli=1#heading=h.jj72y88glvis) (you will need to be a member of the GovWifi Team to view it).

---