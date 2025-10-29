data "aws_kms_key" "rds_kms_key" {
  key_id = "alias/aws/rds"
}

resource "aws_kms_key" "mysql_rds_backup_s3_key" {
  count                   = var.backup_mysql_rds ? 1 : 0
  description             = "This key is used to encrypt RDS MySQL backup bucket objects"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

resource "aws_kms_alias" "mysql_rds_backup_s3_key_alias" {
  count         = var.backup_mysql_rds ? 1 : 0
  name          = "alias/mysql_rds_backup_s3_key"
  target_key_id = aws_kms_key.mysql_rds_backup_s3_key[0].key_id
}
