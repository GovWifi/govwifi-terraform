resource "aws_db_instance" "db" {
  count                       = var.db_instance_count
  allocated_storage           = var.session_db_storage_gb
  storage_type                = "gp3"
  engine                      = "mysql"
  engine_version              = "8.0"
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  apply_immediately           = true
  instance_class              = var.session_db_instance_type
  identifier                  = "wifi-${var.env_name}-db"
  db_name                     = "govwifi_${var.env_name}"
  username                    = local.session_db_username
  password                    = local.session_db_password
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

  enabled_cloudwatch_logs_exports = ["error"]
  option_group_name               = "default:mysql-8-0"
  parameter_group_name            = "default.mysql8.0"

  tags = {
    Name = "${title(var.env_name)} DB"
  }

  lifecycle {
    ignore_changes = [
      username,
      password
    ]
  }
}

resource "aws_db_instance" "read_replica" {
  count                       = var.db_replica_count
  allocated_storage           = var.rr_storage_gb
  replicate_source_db         = aws_db_instance.db[0].identifier
  storage_type                = "gp3"
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  apply_immediately           = true
  instance_class              = var.rr_instance_type
  identifier                  = "${var.env_name}-db-rr"
  backup_retention_period     = 0
  multi_az                    = false
  storage_encrypted           = var.db_encrypt_at_rest
  vpc_security_group_ids      = [aws_security_group.be_db_in.id]
  depends_on                  = [aws_iam_role.rds_monitoring_role]
  monitoring_role_arn         = aws_iam_role.rds_monitoring_role.arn
  monitoring_interval         = var.db_monitoring_interval
  maintenance_window          = var.db_maintenance_window
  backup_window               = var.db_backup_window
  skip_final_snapshot         = true
  option_group_name           = "default:mysql-8-0"
  parameter_group_name        = aws_db_parameter_group.rr_parameters.name
  deletion_protection         = true

  tags = {
    Name = "${title(var.env_name)} DB Read Replica"
  }
}
