locals {
  ## Define log groups for different applications
  ## format "short app/api/group reference name" = "full log group name"
  london_log_groups = {
    "admin"              = "${var.env_name}-admin-log-group",
    "authentication-api" = "${var.env_name}-authentication-api-docker-log-group",
    "logging-api"        = "${var.env_name}-logging-api-docker-log-group",
    "user-signup-api"    = "${var.env_name}-user-signup-api-docker-log-group",
    "radius-docker"      = "${var.env_name}-frontend-docker-log-group",
    "radius"             = "frontend"
  }
  ireland_log_groups = {
    "authentication-api" = "${var.env_name}-authentication-api-docker-log-group",
    "radius-docker"      = "${var.env_name}-frontend-docker-log-group",
    "radius"             = "frontend"
  }
  # If region is London, use London list. Otherwise use Ireland.
  log_groups = var.region == "eu-west-2" ? local.london_log_groups : local.ireland_log_groups

  ## S3 Bucket details for log archive
  ## Bucket created only in London (eu-west-2) for both regions to use, London can reference directly but Dublin needs the ARN.
  log_archive_bucket_name = "govwifi-${var.env}-log-archive"
  log_archive_bucket_id   = var.region == "eu-west-2" ? aws_s3_bucket.log_archive_bucket[0].id : local.log_archive_bucket_name
  log_archive_bucket_arn  = var.region == "eu-west-2" ? aws_s3_bucket.log_archive_bucket[0].arn : "arn:aws:s3:::${local.log_archive_bucket_name}"

  # Configuration required for the Athena view for the app_logs table, which is used for querying the logs in a more user-friendly way.
  # Safely attempt to get the names. If [0] doesn't exist (e.g., in Ireland), return a dummy (null) string.
  modern_logs_table_name = try(aws_glue_catalog_table.modern_logs[0].name, "null")
  athena_db_name         = try(aws_athena_database.govwifi_logs[0].name, "null")
  # The SQL Query for the view
  view_sql = <<EOF
    SELECT
      region,
      app_name,
      logstream,
      date_parse(cast(year as varchar) || '-' || cast(month as varchar) || '-' || cast(day as varchar), '%Y-%m-%d') AS "date",
      from_unixtime(log_event.timestamp / 1000) AS "timestamp",
      log_event.message AS message
    FROM "${local.modern_logs_table_name}"
    CROSS JOIN UNNEST(logevents) AS t(log_event)
    EOF

  # -------------------------------------------------------------
  # 2. PRESTO VIEW DEFINITION (What Athena Engine reads)
  #    Use Presto types: varchar, integer, date, timestamp
  # -------------------------------------------------------------
  presto_view_blob = base64encode(jsonencode({
    originalSql = local.view_sql,
    catalog     = "awsdatacatalog",
    schema      = local.athena_db_name,
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