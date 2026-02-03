# ---------------------------------------------------------
# 1. ATHENA WORKGROUP & DATABASE
# ---------------------------------------------------------
# A dedicated workgroup allows you to separate query history and costs
resource "aws_athena_workgroup" "govwifi_workgroup" {
  name = "govwifi_logs_workgroup"

  configuration {
    result_configuration {
      # Where Athena stores the CSV results of your SELECT queries
      output_location = "s3://${aws_s3_bucket.log_archive_bucket[0].bucket}/athena-results/"
    }
  }
}

resource "aws_athena_database" "govwifi_logs" {
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
  name          = "app_logs"
  database_name = aws_athena_database.govwifi_logs.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "classification"  = "json"
    "compressionType" = "gzip"

    # --- PARTITION PROJECTION CONFIGURATION ---
    # This tells Athena to calculate partitions automatically based on the date
    "projection.enabled"            = "true"

    "projection.date.type"          = "date"
    "projection.date.range"         = "2026/01/01,NOW"
    "projection.date.format"        = "yyyy/MM/dd"
    "projection.date.interval"      = "1"
    "projection.date.interval.unit" = "DAYS"

    "storage.location.template"     = "s3://${aws_s3_bucket.log_archive_bucket[0].bucket}/logs/${"$"}{date}/"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.log_archive_bucket[0].bucket}/logs/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "json-serde"
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    # Standard columns for Firehose JSON logs
    columns {
      name = "timestamp" # Assuming your JSON has this
      type = "string"
    }
    columns {
      name = "log"       # Or "message" - check your Firehose output!
      type = "string"
    }
    columns {
      name = "stream"    # Common in Docker/Container logs
      type = "string"
    }
  }

  # Partition Key (Mapped to projection above)
  partition_keys {
    name = "date"
    type = "string"
  }
}

# ---------------------------------------------------------
# 3. TABLE B: HISTORICAL LOGS (CloudWatch Exports)
#    Format: Regex (Parsing Raw Text)
#    Path: cloudwatch-export/REGION/APP/YYYY/MM/...
# ---------------------------------------------------------

resource "aws_glue_catalog_table" "historical_logs" {
  name          = "historical_logs"
  database_name = aws_athena_database.govwifi_logs.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "classification"  = "text"
    "compressionType" = "gzip"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.log_archive_bucket[0].bucket}/cloudwatch-export/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    # --- REGEX SERDE  ---
    ser_de_info {
      name                  = "historical-regex-serde"
      serialization_library = "org.apache.hadoop.hive.serde2.RegexSerDe"

      parameters = {
        # Regex to parse: "TIMESTAMP  METADATA  LEVEL -- MESSAGE"
        "input.regex" = "^([^\\s]+)\\s+(.*?)\\s+([A-Z]+)\\s+--\\s+(.*)$"
      }
    }

    columns {
      name = "log_timestamp"
      type = "string"
    }
    columns {
      name = "process_info"
      type = "string"
    }
    columns {
      name = "log_level"
      type = "string"
    }
    columns {
      name = "message"
      type = "string"
    }
  }

  # PARTITIONS (Must strictly match S3 folder structure)
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

resource "aws_athena_named_query" "add_historical_partition" {
  name      = "Add Historical Partition (Template)"
  workgroup = aws_athena_workgroup.govwifi_workgroup.id
  database  = aws_athena_database.govwifi_logs.name

  query = <<EOF
-- Usage: Replace values and Run
ALTER TABLE historical_logs
ADD IF NOT EXISTS PARTITION (
    region = 'eu-west-2',
    app_name = 'admin',
    year = '2025',
    month = '05'
)
LOCATION 's3://${aws_s3_bucket.log_archive_bucket[0].bucket}/cloudwatch-export/eu-west-2/admin/2025/05/';
EOF
}