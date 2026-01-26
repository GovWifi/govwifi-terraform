# Production Log Archiving Pipeline

This module configures the long-term log archiving infrastructure for **Production**.

We have replaced CloudWatch retention with a serverless **CloudWatch $\rightarrow$ Firehose $\rightarrow$ S3** pipeline. This retains audit logs for **1 year** at a fraction of the cost of CloudWatch, while keeping them instantly queryable via Amazon Athena.

## ⚠️ Important: Production Environment Only
This architecture is deployed **only to Production**.
* **Dev/Staging:** Logs are retained in CloudWatch for 90 days (or less) and then discarded.
* **Testing:** To test changes to this archiving setup, you must manually replicate this module config in the Development environment, run your tests, and then destroy the resources.

---

## 🏗 Architecture
* **Ingestion:** One dedicated Firehose stream per log group.
* **Format:** Raw text files (GZIP compressed) stored in S3.
* **Structure:** `s3://govwifi-prod-log-archive/logs/<app-name>/YYYY/MM/DD/` (app-name == short reference name/log group/etc, taken from locals config)
* **Storage Class:**
    * **Days 0–30:** S3 Standard (Landing zone).
    * **Days 30–365:** **S3 Standard-IA** (Infrequent Access) – millisecond access, $0.01 per Gb retrieval cost, so watch those queries!
    * **Day 365:** Deleted.

---

## 🛠️ How to Add New Log Groups
To start archiving logs for a new application/api/db/etc, register it in the `locals` block. Terraform will automatically provision the Firehose stream, IAM permissions, and S3 paths.

### 1. Update `locals.tf`
Add your entry to the `log_groups` map:

```hcl
locals {
  ## Define log groups for different applications
  ## Format: "short-reference-name" = "actual-cloudwatch-log-group-name"
  log_groups = {
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
Once applied, logs will begin flowing to S3 within 5 minutes.

---

# Not yet Implemented, subject to change !

## 🔍 How to Query Logs (Athena)

We use **Athena Partition Projection** to map the S3 folder structure to a SQL table. This allows for fast, cost-effective queries without needing to run "crawlers."

### 🛡️ Step 1: Select the Safety Workgroup
You **must** select the following Workgroup in the Athena Console (top-right dropdown):
* **Workgroup:** `log-investigation-safety`

> **Why?** This workgroup enforces a **1GB Data Scan Limit** per query. If you write a "lazy" query (like `SELECT * FROM logs`), it will fail instantly before costly charges apply.

### 📝 Step 2: Write Your Query
There are two tables available for query in Athena:

1. production_logs (Active)
   * Use for: Dates **AFTER** Jan 2026.
   * Format: Optimized, clean text logs.
   * Partitioning: Day-based.
   * Query Syntax: Uses a single date_path string column.
```SQL
WHERE date_path = '2026/01/27'
```

2. historical_logs (Legacy Archive)
  * Use for: Dates **BEFORE** Jan 2026.
  * Format: Raw CloudWatch export (includes Timestamp prefix).
  * Partitioning: Month-based.
  * Query Syntax: Uses separate integer columns for year and month.

```SQL
WHERE year = 2025 AND month = 12
```
Note: In Jan 2027, the Historical table will be retired.

You **must** filter by `app_name` and `date_path`.

**Columns:**
production_logs:
* `message`: The raw log line text.
* `app_name`: The short reference name defined in `locals.tf`.
* `date_path`: The date in format `YYYY/MM/DD`.

historical_logs: The column is named log_data (Timestamp + Text).
* `log_data`: The log line text in the format of Timestamp + Text
* `app_name`: The short reference name defined in `locals.tf`.
* `year` and `month` The date is split over 2 columns year = 2025 and month = 12


#### Example: Specific Day
```sql
SELECT message
FROM production_logs
WHERE app_name = 'admin'
  AND date_path = '2025/12/19'
LIMIT 100;
```
for historical logs that would look like this
```sql
SELECT log_data
FROM historical_logs
WHERE app_name = 'admin'
  AND year = 2025
  AND month = 12
  -- Scan the log content for the timestamp string
  AND log_data LIKE '2025-12-19%'
```

#### Example: Date Range
```sql
SELECT message
FROM production_logs
WHERE app_name = 'api-gateway'
  AND date_path BETWEEN '2025/12/01' AND '2025/12/31'
  AND message LIKE '%error%'
LIMIT 100;
```

## Example scanning both Current and historical logs
```sql
/* Query 1: NEW Logs (Clean) */
SELECT
    date_path AS log_date,
    app_name,
    message,
    'production' AS source
FROM production_logs
WHERE message LIKE '%error%'
  AND date_path > '2025/12/19'

UNION ALL

/* Query 2: OLD Logs (Legacy) */
SELECT
    format('%04d/%02d', year, month) AS log_date, -- Approximate date (Month only)
    app_name,
    log_data AS message,
    'historical' AS source
FROM historical_logs
WHERE
  AND year = 2025
  AND month = 12
  log_data LIKE '%error%'
```

> **Note:** If you get an error saying *“Partition constraint violation”* or zero results, check that you included the `app_name` and `date_path` in your `WHERE` clause.


---

# Can be removed once archiving is complete.
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

