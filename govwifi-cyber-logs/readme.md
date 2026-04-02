### Cribl-cloudwatch-kinesis for Admin Portal

The terraform creates all necessary resources to push log files to Kinesis aka Cribl, which in turn sends logs to Cyber Splunk.

### 1. Update `locals.tf`
Add your entry to the `log_groups` map:
There are 2 maps, one for each region
london_log_groups and ireland_log_groups
There is a switch at the bottom of the file which will deploy the log config dependant upon region.

```hcl
locals {
  ## Define log groups for different applications
  ## Format: "short-reference-name" = "actual-cloudwatch-log-group-name"
  london_log_groups = {
    "admin"       = "${var.env_name}-admin-log-group",
    "auth-api" = "/aws/authentication-api/prod-api",
    # Add new app here:
    # "my-new-app" = "production-app-log-group-name"
  }
}
```
* **Key (Left):** The "Short Name" (e.g., `my-new-app`). This becomes the folder name in S3 and the `app_name` in Athena.
* **Value (Right):** The exact CloudWatch Log Group name.