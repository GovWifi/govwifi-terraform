# ---------------------------------------------------------
# 1. ATHENA WORKGROUP & DATABASE
# ---------------------------------------------------------
# A dedicated workgroup allows you to separate query history and costs
resource "aws_athena_workgroup" "govwifi_logs_workgroup" {
  count = var.region == "eu-west-2" ? 1 : 0
  name  = "govwifi_logs_workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    result_configuration {
      # Where Athena stores the CSV results of your SELECT queries
      output_location = "s3://${aws_s3_bucket.log_archive_bucket[0].bucket}/athena-results/"
    }
    # --- SAFETY BRAKE ---
    # Cancel any query that scans more than 10 GB ($0.05).
    # This prevents accidental "SELECT *" on the whole dataset.
    bytes_scanned_cutoff_per_query = 10737418240 # 10 GB in Bytes
  }
}

resource "aws_athena_database" "govwifi_logs" {
  count  = var.region == "eu-west-2" ? 1 : 0
  name   = "govwifi_logs"
  bucket = aws_s3_bucket.log_archive_bucket[0].bucket
}

# ---------------------------------------------------------
# 2. TABLE A: Current LOGS (Live Firehose Data)
#    Format: JSON (Standard Firehose)
#    Path: logs/YYYY/MM/DD/
#    Automation: Uses Partition Projection (No manual repairs needed!)
# ---------------------------------------------------------

resource "aws_glue_catalog_table" "modern_logs" {
  count         = var.region == "eu-west-2" ? 1 : 0
  name          = "app_logs"
  database_name = aws_athena_database.govwifi_logs[0].name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "classification"     = "json"
    "EXTERNAL"           = "TRUE"
    "projection.enabled" = "true"

    # --- 1. REGION PROJECTION ---
    # We use 'enum' here. It allows you to list the specific regions you expect.
    # If you have multiple, separate them with commas (e.g., "eu-west-2,eu-west-1").
    "projection.region.type"   = "enum"
    "projection.region.values" = var.region

    # --- 2. APP NAME PROJECTION ---
    # We use 'injected' so you can query ANY app name without updating this table definition.
    # NOTE: You must include "WHERE app_name = '...'" in your queries, app_name is the short name in the locals config.
    "projection.app_name.type" = "enum"
    # List all your apps here, comma-separated
    "projection.app_name.values" = "admin,authentication-api,logging-api,user-signup-api,radius,radius-docker"

    # --- 3. DATE PROJECTIONS ---
    "projection.year.type"   = "integer"
    "projection.year.range"  = "2026,2046"
    "projection.year.digits" = "4"

    "projection.month.type"   = "integer"
    "projection.month.range"  = "1,12"
    "projection.month.digits" = "2"

    "projection.day.type"   = "integer"
    "projection.day.range"  = "1,31"
    "projection.day.digits" = "2"

    # 3. The Template (Crucial! Matches your Firehose prefix)
    "storage.location.template" = "s3://${aws_s3_bucket.log_archive_bucket[0].bucket}/logs/$${region}/$${app_name}/$${year}/$${month}/$${day}" ## double $$ to escape for Terraform
  }

  # -------------------------------------------------------
  # 1. PARTITION KEYS (The Folder Structure)
  # -------------------------------------------------------
  partition_keys {
    name = "region"
    type = "string"
  }
  partition_keys {
    name = "app_name"
    type = "string"
  }
  partition_keys {
    name = "year"
    type = "string"
  }
  partition_keys {
    name = "month"
    type = "string"
  }
  partition_keys {
    name = "day"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.log_archive_bucket[0].bucket}/logs/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "json_serde"
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"

      parameters = {
        "ignore.malformed.json" = "TRUE"      # Prevents query failure on bad lines
        "mapping.timestamp"     = "timestamp" # Optional mapping just in case
      }
    }

    # -------------------------------------------------------
    # 2. Define Columns (Standard CloudWatch Schema)
    # -------------------------------------------------------

    columns {
      name = "messagetype"
      type = "string"
    }
    columns {
      name = "loggroup"
      type = "string"
    }
    columns {
      name = "logstream"
      type = "string"
    }
    columns {
      name = "subscriptionfilters"
      type = "array<string>"
    }
    columns {
      name = "logevents"
      type = "array<struct<id:string,timestamp:bigint,message:string>>"
    }
  }
}

# ---------------------------------------------------------
# 2a. SIMPLIFIED VIEW of 'app_logs' table.
#    Makes it simpler to query the logs without having to remember complex sql
#    Programmatically Create the View linked to table, work around for running sql to create the view.
#   Views are a special type of Glue Table wrapped in a Presto-specific envelope, handle with care!
# ---------------------------------------------------------

resource "aws_glue_catalog_table" "active_logs_view" {
  count         = var.region == "eu-west-2" ? 1 : 0
  name          = "app_logs_view"
  database_name = aws_athena_database.govwifi_logs[0].name
  table_type    = "VIRTUAL_VIEW"

  parameters = {
    "presto_view" = "true"
    "comment"     = "View for flattened app logs with partition pruning"
  }

  view_original_text = "/* Presto View: ${local.presto_view_blob} */"
  view_expanded_text = "/* Presto View */"

  storage_descriptor {
    location = "" # Views do not have a physical location, but will fail if empty, adding a .
    ser_de_info {
      name                  = "."
      serialization_library = "."
    }

    # -------------------------------------------------------------
    # 1. HIVE COLUMNS (What Glue/Athena Catalog sees)
    #    Use Hive types: string, int, date, timestamp
    # -------------------------------------------------------------
    columns {
      name = "region"
      type = "string"
    }
    columns {
      name = "app_name"
      type = "string"
    }
    columns {
      name = "logstream"
      type = "string"
    }
    columns {
      name = "date"
      type = "date"
    }
    columns {
      name = "timestamp"
      type = "timestamp"
    }
    columns {
      name = "message"
      type = "string"
    }
  }
}

locals {
  # The SQL Query for the view
  view_sql = <<EOF
SELECT
  region,
  app_name,
  logstream,
  date_parse(cast(year as varchar) || '-' || cast(month as varchar) || '-' || cast(day as varchar), '%Y-%m-%d') AS "date",
  from_unixtime(log_event.timestamp / 1000) AS "timestamp",
  log_event.message AS message
FROM "${aws_glue_catalog_table.modern_logs[0].name}"
CROSS JOIN UNNEST(logevents) AS t(log_event)
EOF

  # -------------------------------------------------------------
  # 2. PRESTO VIEW DEFINITION (What Athena Engine reads)
  #    Use Presto types: varchar, integer, date, timestamp
  # -------------------------------------------------------------
  presto_view_blob = base64encode(jsonencode({
    originalSql = local.view_sql,
    catalog     = "awsdatacatalog",
    schema      = aws_athena_database.govwifi_logs[0].name,
    columns = [
      { name = "region", type = "varchar" },
      { name = "app_name", type = "varchar" },
      { name = "logstream", type = "varchar" },
      { name = "date", type = "date" },
      { name = "timestamp", type = "timestamp" },
      { name = "message", type = "varchar" }
    ]
  }))
}


# ---------------------------------------------------------
# 3. TABLE B: HISTORICAL LOGS (CloudWatch Exports)
#    Format: Regex (Parsing Raw Text)
#    Path: cloudwatch-export/REGION/APP/YYYY/MM/...
# ---------------------------------------------------------

resource "aws_glue_catalog_table" "historical_logs" {
  count         = var.region == "eu-west-2" ? 1 : 0
  name          = "historical_logs"
  database_name = aws_athena_database.govwifi_logs[0].name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "classification"     = "text"
    "compressionType"    = "gzip"
    "projection.enabled" = "true"

    # --- TIME ---
    "projection.year.type"    = "integer"
    "projection.year.range"   = "2025,2026"
    "projection.month.type"   = "integer"
    "projection.month.range"  = "1,12"
    "projection.month.digits" = "2"

    # --- APPS ---
    "projection.app_name.type"   = "enum"
    "projection.app_name.values" = "admin,radius,radius-docker,authentication-api,logging-api,user-signup-api"

    # --- REGIONS ---
    # Tells Athena that valid data exists in both region folders
    "projection.region.type"   = "enum"
    "projection.region.values" = "eu-west-1,eu-west-2"

    "storage.location.template" = "s3://${aws_s3_bucket.log_archive_bucket[0].bucket}/cloudwatch-export/$${region}/$${app_name}/$${year}/$${month}/" ## double $$ to escape for Terraform
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.log_archive_bucket[0].bucket}/cloudwatch-export/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    # Regex to parse the text logs
    ser_de_info {
      name                  = "historical-regex-serde"
      serialization_library = "org.apache.hadoop.hive.serde2.RegexSerDe"
      parameters = {
        "input.regex" = "^(^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}.\\d{3}Z)(.*)$"
      }
    }

    columns {
      name = "log_timestamp"
      type = "string"
    }
    columns {
      name = "message"
      type = "string"
    }
  }

  partition_keys {
    name = "region"
    type = "string"
  }
  partition_keys {
    name = "app_name"
    type = "string"
  }
  partition_keys {
    name = "year"
    type = "string"
  }
  partition_keys {
    name = "month"
    type = "string"
  }
}

# ---------------------------------------------------------
# 4. HELPER: SAVED QUERIES
#    Saves you from typing the 'ALTER TABLE' command manually
# ---------------------------------------------------------

# Query 1. Live System: Recent logs
resource "aws_athena_named_query" "search_modern" {
  count = var.region == "eu-west-2" ? 1 : 0

  name        = "1. Live System: Recent Errors"
  workgroup   = aws_athena_workgroup.govwifi_logs_workgroup[0].id
  database    = aws_athena_database.govwifi_logs[0].name
  description = "Search the last 7 days of live logs (JSON)."

  query = <<EOF
SELECT "timestamp", app_name, message
FROM app_logs_view
WHERE region = 'eu-west-2'
  AND "date" >= current_date - interval '7' day
  AND app_name = 'admin'
  AND message LIKE '%ERROR%'
ORDER BY "timestamp" DESC
LIMIT 100;
EOF
}

# Query 2: Historical log query template (Must edit partitions before running)
resource "aws_athena_named_query" "add_historical_partition" {
  count       = var.region == "eu-west-2" ? 1 : 0
  name        = "2. historical logs: By app and month"
  workgroup   = aws_athena_workgroup.govwifi_logs_workgroup[0].id
  database    = aws_athena_database.govwifi_logs[0].name
  description = "Search specifically through the migrated Ireland archive from 2025."

  query = <<EOF
SELECT log_timestamp, app_name, message
FROM historical_logs
WHERE region = 'eu-west-1'
  AND year = '2025'
  AND month = '12'
  AND message LIKE '%ERROR%'
ORDER BY log_timestamp ASC
LIMIT 100;
EOF
}

# Query 3: Cross-Region Stats
resource "aws_athena_named_query" "compare_regions" {
  count       = var.region == "eu-west-2" ? 1 : 0
  name        = "3. historical logs: Compare Regions"
  workgroup   = aws_athena_workgroup.govwifi_logs_workgroup[0].id
  database    = aws_athena_database.govwifi_logs[0].name
  description = "Count logs by region to verify the migration worked."

  query = <<EOF
SELECT region, count(*) as log_count
FROM historical_logs
WHERE year = '2025'
AND month = '05'
GROUP BY region;
EOF
}

# QUERY 4: CROSS-REGION & CROSS-ERA (The "All-In" Search) example.
# Best for: "Find this specific message, I don't care where or when it happened."
# Strategy: Uses UNION ALL to combine both tables on the fly without a permanent View.
resource "aws_athena_named_query" "search_combined" {
  count       = var.region == "eu-west-2" ? 1 : 0
  name        = "4. Global Search: Modern + Historical"
  workgroup   = aws_athena_workgroup.govwifi_logs_workgroup[0].id
  database    = aws_athena_database.govwifi_logs[0].name
  description = "Search EVERYTHING (Live London logs + Archived Ireland logs) for a keyword."

  query = <<EOF
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
EOF
}