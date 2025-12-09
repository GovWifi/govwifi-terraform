resource "aws_cloudwatch_metric_alarm" "sessions_db_cpu" {
  count               = var.db_instance_count
  alarm_name          = "${var.env_name}-sessions-db-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "80"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.db[0].identifier
  }

  alarm_description  = "Database CPU utilization exceeding threshold. Investigate database logs for root cause."
  alarm_actions      = [var.critical_notifications_arn]
  treat_missing_data = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "sessions_db_memory" {
  count               = var.db_instance_count
  alarm_name          = "${var.env_name}-sessions-db-memory-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "524288000"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.db[0].identifier
  }

  alarm_description  = "Database is running low on free memory. Investigate database logs for root cause."
  alarm_actions      = [var.critical_notifications_arn]
  treat_missing_data = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "sessions_db_storage" {
  count               = var.db_instance_count
  alarm_name          = "${var.env_name}-sessions-db-storage-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Minimum"
  threshold           = var.db_storage_alarm_threshold

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.db[0].identifier
  }

  alarm_description  = "Database is running low on free storage space. Investigate database logs for root cause."
  alarm_actions      = [var.critical_notifications_arn]
  treat_missing_data = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "sessions_db_burst_balance" {
  count               = var.db_instance_count
  alarm_name          = "${var.env_name}-sessions-db-burst-balance-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "BurstBalance"
  namespace           = "AWS/RDS"
  period              = "180"
  statistic           = "Minimum"
  threshold           = "45"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.db[0].identifier
  }

  alarm_description  = "Database's available IOPS burst balance is running low. Investigate disk usage on the RDS instance."
  alarm_actions      = [var.critical_notifications_arn]
  treat_missing_data = "missing"
}

# Triggers if the DB instance uses excessing swap space consistently (indicates RAM pressure)
resource "aws_cloudwatch_metric_alarm" "db_swap_usage_alarm" {
  count               = var.db_instance_count
  alarm_name          = "${var.env_name}-sessions-db-SwapUsage-Alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "SwapUsage"
  namespace           = "AWS/RDS"
  period              = 60 # 5 minutes total (5 periods * 60 seconds)
  statistic           = "Average"
  threshold           = 52428800 # 50 MB
  unit                = "Bytes"
  alarm_description   = "Triggers when the DB instance uses any swap space (memory is insufficient)."
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.db[0].identifier
  }

  alarm_actions = [var.capacity_notifications_arn]
}

# Triggers if connections exceed 80% of the max_connections limit.
# Note: Max connections is dynamic based on instance size; 80% is a safe general warning.
resource "aws_cloudwatch_metric_alarm" "db_connections_high_alarm" {
  count               = var.db_instance_count
  alarm_name          = "${var.env_name}-session-db-HighConnections-Alert"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 5
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300 # 5 minutes
  statistic           = "Average"

  # Set the threshold based on 80% of your instance's max_connections value.
  # If max_connections for m5-xlarge is 1365, 80% of that is 1092 so set to 1092
  threshold          = 1092
  unit               = "Count"
  alarm_description  = "Triggers when database connections exceed 80% of the maximum limit. Log into the database to check active connections and queries. If this is exceeded often consider increasing instance size."
  treat_missing_data = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.db[0].identifier
  }

  alarm_actions = [var.critical_notifications_arn]
}

# Triggers if I/O requests consistently wait in the queue (indicating saturation).
# Threshold is set low (>= 5) as we have 5000 IOPS and expect the queue to be near zero.
resource "aws_cloudwatch_metric_alarm" "db_queue_depth_alarm" {
  count               = var.db_instance_count
  alarm_name          = "${var.env_name}-session-db-HighQueueDepth-Alert"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "DiskQueueDepth"
  namespace           = "AWS/RDS"
  period              = 60 # 3 minutes total
  statistic           = "Average"
  threshold           = 5
  unit                = "Count"
  alarm_description   = "Triggers when I/O requests consistently wait in the disk queue. log into to database and look at processelist for stalled queries."
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.db[0].identifier
  }

  alarm_actions = [var.capacity_notifications_arn]
}


#### Read Replica Alarms ####
resource "aws_cloudwatch_metric_alarm" "sessions_rr_burst_balance" {
  count               = var.db_replica_count
  alarm_name          = "${var.env_name}-sessions-rr-burst-balance-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "BurstBalance"
  namespace           = "AWS/RDS"
  period              = "180"
  statistic           = "Minimum"
  threshold           = "45"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.read_replica[0].identifier
  }

  alarm_description  = "Read replica database's available IOPS burst balance is running low. Investigate disk usage on the RDS instance."
  alarm_actions      = [var.capacity_notifications_arn]
  treat_missing_data = "missing"
}

resource "aws_cloudwatch_metric_alarm" "sessions_rr_lagging" {
  count               = var.db_replica_count
  alarm_name          = "${var.env_name}-sessions-rr-lagging-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "ReplicaLag"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "60"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.read_replica[0].identifier
  }

  alarm_description  = "Read replica database replication lag exceeding threshold. Investigate connections to the primary database."
  alarm_actions      = [var.capacity_notifications_arn]
  treat_missing_data = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "sessions_rr_cpu" {
  count               = var.db_replica_count
  alarm_name          = "${var.env_name}-sessions-rr-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "80"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.read_replica[0].identifier
  }

  alarm_description  = "Read replica database CPU utilization exceeding threshold. Investigate database logs for root cause."
  alarm_actions      = [var.capacity_notifications_arn]
  treat_missing_data = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "sessions_rr_memory" {
  count               = var.db_replica_count
  alarm_name          = "${var.env_name}-sessions-rr-memory-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "524288000"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.read_replica[0].identifier
  }

  alarm_description  = "Read replica database is running low on free memory. Investigate database logs for root cause."
  alarm_actions      = [var.capacity_notifications_arn]
  treat_missing_data = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "sessions_rr_storage" {
  count               = var.db_replica_count
  alarm_name          = "${var.env_name}-sessions-rr-storage-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "32212254720"
  datapoints_to_alarm = "1"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.read_replica[0].identifier
  }

  alarm_description  = "Read replica database is running low on free storage space. Investigate database logs for root cause."
  alarm_actions      = [var.capacity_notifications_arn]
  treat_missing_data = "breaching"
}


