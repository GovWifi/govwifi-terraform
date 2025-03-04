resource "aws_db_instance" "users_db" {
  count                       = var.db_instance_count
  allocated_storage           = var.user_db_storage_gb
  storage_type                = "gp2"
  engine                      = "mysql"
  engine_version              = "8.0"
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  apply_immediately           = true
  instance_class              = var.user_db_instance_type
  identifier                  = "wifi-${var.env}-user-db"
  db_name                     = "govwifi_${var.env}_users"
  username                    = local.users_db_username
  password                    = local.users_db_password
  backup_retention_period     = var.db_backup_retention_days
  multi_az                    = true
  storage_encrypted           = var.db_encrypt_at_rest
  db_subnet_group_name        = "wifi-${var.env_name}-subnets"
  vpc_security_group_ids      = [aws_security_group.be_db_in.id]
  depends_on                  = [aws_iam_role.rds_monitoring_role]
  monitoring_role_arn         = aws_iam_role.rds_monitoring_role.arn
  monitoring_interval         = var.db_monitoring_interval
  maintenance_window          = var.db_maintenance_window
  backup_window               = var.db_backup_window
  skip_final_snapshot         = true
  deletion_protection         = true

  enabled_cloudwatch_logs_exports = ["error", "slowquery"]
  option_group_name               = aws_db_option_group.user_mariadb_audit[0].name
  parameter_group_name            = aws_db_parameter_group.user_db_parameters[0].name

  tags = {
    Name = "${title(var.env)} Users DB"
  }

  lifecycle {
    ignore_changes = [
      username,
      password
    ]
  }

}

resource "aws_db_instance" "users_read_replica" {
  count                       = var.user_db_replica_count
  replicate_source_db         = var.user_replica_source_db
  kms_key_id                  = data.aws_kms_key.rds_kms_key.arn
  storage_encrypted           = var.db_encrypt_at_rest
  storage_type                = "gp2"
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  apply_immediately           = true
  instance_class              = var.user_rr_instance_type
  identifier                  = "wifi-${var.env}-user-rr"
  password                    = local.users_db_password
  backup_retention_period     = 0
  multi_az                    = true
  vpc_security_group_ids      = [aws_security_group.be_db_in.id]
  monitoring_role_arn         = aws_iam_role.rds_monitoring_role.arn
  monitoring_interval         = var.db_monitoring_interval
  maintenance_window          = var.db_maintenance_window
  backup_window               = var.db_backup_window
  skip_final_snapshot         = true
  parameter_group_name        = aws_db_parameter_group.user_rr_parameters[0].name
  db_subnet_group_name        = "wifi-${var.env_name}-subnets"
  deletion_protection         = true

  depends_on = [aws_db_instance.users_db]

  tags = {
    Name = "${title(var.env_name)} DB Read Replica"
  }

  lifecycle {
    ignore_changes = [
      username,
      password
    ]
  }
}

