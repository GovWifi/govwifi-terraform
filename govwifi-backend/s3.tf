# Bucket to store MySQL RDS backups
# Please notify the CDIO IT team if the bucket name is changed.
# The bucket is used in the GovWifi's offsite backup script.
resource "aws_s3_bucket" "rds_mysql_backup_bucket" {
  count         = var.backup_mysql_rds ? 1 : 0
  bucket        = "govwifi-${var.env_name}-${lower(var.aws_region_name)}-mysql-backup-data"
  force_destroy = true

  tags = {
    Name     = "GovWifi ${title(var.env_name)} RDS MySQL data backup"
    Region   = title(var.aws_region_name)
    Category = "MySQL RDS data backup"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "rds_mysql_backup_bucket" {
  count  = var.backup_mysql_rds ? 1 : 0
  bucket = aws_s3_bucket.rds_mysql_backup_bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = "alias/mysql_rds_backup_s3_key"
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "rds_mysql_backup_bucket" {
  count  = var.backup_mysql_rds ? 1 : 0
  bucket = aws_s3_bucket.rds_mysql_backup_bucket[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "rds_mysql_backup_bucket" {
  count      = var.backup_mysql_rds ? 1 : 0
  depends_on = [aws_s3_bucket_versioning.rds_mysql_backup_bucket[0]]

  bucket = aws_s3_bucket.rds_mysql_backup_bucket[0].id

  rule {
    id = "expiration"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    expiration {
      days = 180
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "rds_mysql_backup_bucket" {
  count  = var.backup_mysql_rds ? 1 : 0
  bucket = aws_s3_bucket.rds_mysql_backup_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_replication_configuration" "rds_mysql_backup_bucket" {
  count      = var.recovery_backups_enabled ? 1 : 0
  depends_on = [aws_s3_bucket_versioning.rds_mysql_backup_bucket]

  role   = aws_iam_role.iam_for_recovery_database_backup[0].arn
  bucket = aws_s3_bucket.rds_mysql_backup_bucket[0].id

  rule {
    id       = "ReplicateDB"
    priority = 0
    status   = "Enabled"

    filter {} # empty filter matches the entire bucket

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket  = "arn:aws:s3:::govwifi-database-backups"
      account = data.aws_secretsmanager_secret_version.recovery_account[0].secret_string

      access_control_translation {
        owner = "Destination"
      }

      encryption_configuration {
        replica_kms_key_id = "arn:aws:kms:eu-west-2:${data.aws_secretsmanager_secret_version.recovery_account[0].secret_string}:key/${data.aws_secretsmanager_secret_version.recovery_kms_key[0].secret_string}"
      }

      replication_time {
        status = "Enabled"

        time {
          minutes = 15
        }
      }

      metrics {
        status = "Enabled"

        event_threshold {
          minutes = 15
        }
      }
    }

    delete_marker_replication {
      status = "Disabled"
    }
  }
}

