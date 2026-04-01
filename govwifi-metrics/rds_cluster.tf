
resource "aws_rds_cluster" "metrics_db_cluster" {
  cluster_identifier     = "metrics-db-cluster-${var.aws_region}-${var.env}"
  engine                 = var.engine
  engine_mode            = "provisioned"
  engine_version         = var.engine_version
  database_name          = var.database_name
  master_username        = jsondecode(data.aws_secretsmanager_secret_version.metrics_db_credentials_data.secret_string)["username"]
  master_password        = jsondecode(data.aws_secretsmanager_secret_version.metrics_db_credentials_data.secret_string)["password"]
  vpc_security_group_ids = [aws_security_group.london_metrics_db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.london_metrics_db_subnet_group.name
  skip_final_snapshot    = var.skip_final_snapshot

  serverlessv2_scaling_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  tags = var.tags
}

resource "aws_rds_cluster_instance" "metrics_db_cluster_instance" {
  count                = var.instance_count
  identifier           = "metrics-db-cluster-${var.aws_region}-${count.index}"
  cluster_identifier   = aws_rds_cluster.metrics_db_cluster.id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.metrics_db_cluster.engine
  engine_version       = aws_rds_cluster.metrics_db_cluster.engine_version
  db_subnet_group_name = aws_rds_cluster.metrics_db_cluster.db_subnet_group_name

  tags = var.tags
}
