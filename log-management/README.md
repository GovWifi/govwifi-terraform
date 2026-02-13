# Production Log Archiving Pipeline

This module configures the long-term log archiving infrastructure for **Production**.  Intended for logs are are required to be kept for 12 months, anything up to 3 months should be kept in cloudwatch with a max of 3 month retention period.

We have replaced CloudWatch yearly retention with a serverless **CloudWatch $\rightarrow$ Firehose $\rightarrow$ S3** pipeline. This retains audit logs for **1 year**, while the logs remain instantly queryable via Amazon Athena.

## ⚠️ Important: Production Environment Only
This architecture is deployed **only to Production**.
* **Dev/Staging:** Logs are retained in CloudWatch for 90 days (or less) and then discarded.
* **Testing:** To test changes to this archiving setup, you must manually replicate this module config in the Development environment, run your tests, and then destroy the resources.

---

## 🏗 Architecture
* **Ingestion:** One dedicated Firehose stream per log group.
* **Format:** Raw text files (GZIP compressed) stored in S3.
* **Structure:** `s3://govwifi-prod-log-archive/logs/<region>/<app-name>/YYYY/MM/DD/` (app-name == short reference name/log group/etc, taken from locals config)
* **Storage Class:**
    * **Days 0–30:** S3 Standard (Landing zone).
    * **Days 30–365:** **S3 Standard-IA** (Infrequent Access) – millisecond access, $0.01 per Gb retrieval cost, so watch those queries!
    * **Day 365:** Deleted.

---

## 🛠️ How to Add New Log Groups
To start archiving logs for a new application/api/db/etc, register it in the `locals` block. Terraform will automatically provision the Firehose stream, IAM permissions, and S3 paths.

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

### 2. Apply Terraform
Once applied, logs will begin flowing to S3 within 15 minutes.

---

## 🔍 How to Query Logs (Cloudwatch < 90 days)
* For logs < 90 days, continue to use Cloudwatch and Filters, this is your fastest and most known way.
* for logs > 90 days use Amazon Athena as described below.

## 🔍 How to Query Logs (Athena > 90 days)
We use **Athena Partition Projection** to map the S3 folder structure to a SQL table. This allows for fast, cost-effective queries without needing to run "crawlers."

In the AWS console, search for Athena, then click the left hand hamburger menu to expand it. \
From the expanded left menu select **Query Editor**,

### 🛡️ Step 1: Select the log Workgroup and database
#### WorkGroup
Then select the workgroup **govwifi_logs_workgroup** from the menu on the top-right dropdown, **<< Very Important**
This will then switch you into that workgroup, which as some saved queries to get you started, select the saved queries tab to see them.

You **must** select the following Workgroup in the Athena query editor Console (top-right dropdown):
* **Workgroup:** `govwifi_logs_workgroup`

> **Why?** This workgroup enforces a **1GB Data Scan Limit** per query. If you write a "lazy" query (like `SELECT * FROM logs`), it will fail instantly before costly charges apply.

#### Database
From the left hand menu under databases select **govwifi_logs**, if you don't do this, the queries will not work as the tables will not be found.

### 📝 Step 2: Write Your Query
There are two tables and 1 view available for query in Athena: (if the tables show 0, you've not selected the database, see step 1)

A 'view' has been created for the app_logs table to simply the querying of the data, to look at current logs, use the **app_logs_view** view instead of teh table.

1. app_logs_view (Active / current logs)
   * Use for: Dates **AFTER** Mar 2026.
   * Format: Optimized, clean Json logs.
   * Partitioning: Region, App and date, Day-based.
   * Query Syntax: Uses a single date string column.
```SQL
WHERE date = '2026-01-27'
```

2. historical_logs (Legacy Archive)
  * Use for: Dates **BEFORE** Mar 2026.
  * Format: Raw CloudWatch export (includes Timestamp prefix).
  * Partitioning: Region, App and date, Month-based.
  * Query Syntax: Uses separate integer columns for year and month.

```SQL
WHERE year = 2025 AND month = 12
```
Note: In Jan 2027, the Historical table will be retired as the logs will expire.

You **must** filter by `app_name`, `region` and `date`.

**Columns:**
app_logs_view:
* `message`: The raw log line text.
* `region`: The region the logs were created from
* `app_name`: The short reference name defined in `locals.tf`.
* `date`: The date in format `YYYY-MM-DD`.

historical_logs: The column is named log_data (Timestamp + Text).
* `message`: The log line text in the format of Timestamp + Text
* `region`: The region the logs were created from
* `app_name`: The short reference name defined in `locals.tf`.
* `year` and `month` The date is split over 2 columns year = 2025 and month = 12


#### Example: Specific Day
```sql
SELECT message
FROM app_logs
WHERE region = 'eu-west-2'
  AND app_name = 'admin'
  AND date = DATE '2025-12-19'
LIMIT 100;
```
for historical logs that would look like this
Scans the log content for the timestamp string
```sql
SELECT message
FROM historical_logs
WHERE region = 'eu-west-2'
  AND app_name = 'admin'
  AND year = '2025'
  AND month = '12'
  AND message LIKE '2025-12-19%'
```

#### Example: Date Range
```sql
SELECT message
FROM app_logs_view
WHERE region = 'eu-west-2'
  AND app_name = 'logging-api'
  AND date BETWEEN DATE '2025-12-01' AND DATE '2025-12-31'
  AND message LIKE '%error%'
LIMIT 100;
```

## Example scanning both Current and historical logs
```sql
SELECT
    'Live-' || region AS source,
    "timestamp",
    app_name,
    message
FROM app_logs_view
WHERE message LIKE '%healthcheck%'
  AND date >= DATE '2026-03-01'
  AND app_name = 'admin'
UNION ALL

SELECT
    'Archive-' || region AS source,
    from_iso8601_timestamp(log_timestamp) AS "timestamp",
    app_name,
    message
FROM historical_logs
WHERE message LIKE '%healthcheck%'
  AND year = '2026'
  AND app_name = 'admin'
ORDER BY timestamp DESC
LIMIT 50;

```

> **Note 1:** If you see an error like  *“Partition constraint violation”* or zero results, check that you included the `app_name` and `date_path` in your `WHERE` clause.

> **Note 2:** if you see an error like **COLUMN_NOT_FOUND: line 4:18: Column 'xxx' cannot be resolved or requester is not authorized to access requested resources ** ensure the use of single quotes, there is no syntax correction it would seem.

---

## 🔄 Retention & Migration Workflow

### 1. Daily Workflow
* **Recent Logs (< 90 Days):** Use CloudWatch Insights. It is faster and easier for recent debugging.
* **Older Logs (> 90 Days):** Use Athena (S3).

### 2. Onboarding New Apps (Backfilling)
When you first add an app to Firehose, S3 will only contain *new* logs. To fill the gap (e.g., the last 9 months of data), you must manually export the old logs from CloudWatch.

Run the provided script locally:
```bash
/scripts/log_migration.sh <log-group-name> <short-app-name>
```

### 3. Reducing CloudWatch Costs
**After** verifying logs are landing in S3:
1.  Go to the specific application's Terraform module.
2.  Update the `aws_cloudwatch_log_group` resource:
    ```hcl
    retention_in_days = 90
    ```
    or, preferably us a module variable
    ```hcl
    retention_in_days = var.log_retention
    ```

3.  Apply the change. This creates the cost savings.

