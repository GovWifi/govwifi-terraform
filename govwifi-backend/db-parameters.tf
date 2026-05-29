resource "aws_db_subnet_group" "db_subnets" {
  name        = "wifi-${var.env_name}-subnets"
  description = "GovWifi ${var.env_name} backend subnets"
  subnet_ids  = [for subnet in aws_subnet.wifi_backend_subnet : subnet.id]

  tags = {
    Name = "wifi-${var.env_name}-subnets"
  }
}

resource "aws_db_parameter_group" "db_parameters" {
  count       = var.db_instance_count
  name        = "${var.env_name}-db-parameter-group"
  family      = "mysql8.4"
  description = "DB parameter configuration"

  parameter {
    name  = "slow_query_log"
    value = 1
  }

  parameter {
    name  = "general_log"
    value = 0
  }

  parameter {
    name  = "log_queries_not_using_indexes"
    value = 1
  }

  parameter {
    name  = "log_output"
    value = "FILE"
  }

  tags = {
    Name = "${title(var.env_name)} DB parameter group"
  }
}

resource "aws_db_parameter_group" "user_db_parameters" {
  count       = var.db_instance_count
  name        = "${var.env_name}-user-db-parameter-group"
  family      = "mysql8.0"
  description = "User DB parameter configuration"

  parameter {
    name  = "slow_query_log"
    value = 1
  }

  parameter {
    name  = "general_log"
    value = 0
  }

  parameter {
    name  = "log_queries_not_using_indexes"
    value = 1
  }

  parameter {
    name  = "log_output"
    value = "FILE"
  }

  tags = {
    Name = "${title(var.env_name)} User DB parameter group"
  }
}

resource "aws_db_parameter_group" "rr_parameters" {
  name = "${var.env_name}-rr-parameter-group"

  family      = "mysql8.4"
  description = "DB read replica parameter configuration"

  parameter {
    name  = "slow_query_log"
    value = 1
  }

  parameter {
    name  = "general_log"
    value = 0
  }

  parameter {
    name  = "log_queries_not_using_indexes"
    value = 1
  }

  parameter {
    name  = "log_output"
    value = "FILE"
  }

  tags = {
    Name = "${title(var.env_name)} DB read replica parameter group"
  }
}

resource "aws_db_parameter_group" "user_rr_parameters" {
  count = var.user_db_replica_count
  name  = "${var.env_name}-user-rr-parameter-group"

  family      = "mysql8.0"
  description = "DB read replica parameter configuration"

  parameter {
    name  = "slow_query_log"
    value = 1
  }

  parameter {
    name  = "general_log"
    value = 0
  }

  parameter {
    name  = "log_queries_not_using_indexes"
    value = 1
  }

  parameter {
    name  = "log_output"
    value = "FILE"
  }

  tags = {
    Name = "${title(var.env_name)} User DB read replica parameter group"
  }
}

resource "aws_db_option_group" "mariadb_audit" {
  name = "${var.env_name}-db-audit"

  option_group_description = "Mariadb audit configuration"
  engine_name              = "mysql"
  major_engine_version     = "8.4"

  option {
    option_name = "MARIADB_AUDIT_PLUGIN"
  }

  tags = {
    Name = "${title(var.env_name)} DB Audit configuration"
  }
}

resource "aws_db_option_group" "user_mariadb_audit" {
  count = var.db_instance_count
  name  = "${var.env}-user-db-audit"

  option_group_description = "Mariadb audit configuration"
  engine_name              = "mysql"
  major_engine_version     = "8.0"

  tags = {
    Name = "${title(var.env)} User DB Audit configuration"
  }
}

