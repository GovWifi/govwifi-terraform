resource "aws_codebuild_project" "tableau_data_source_publication" {
  name          = "tableau-data-source-publication"
  description   = "This publishes the metrics data source(s) to Tableau using the https://github.com/GovWifi/govwifi-metrics-data-publisher repo"
  service_role  = var.govwifi_codebuild_role_arn
  build_timeout = "20"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "BRANCH"
      value = var.metrics_data_publisher_repository_branch
    }

    environment_variable {
      name  = "METRICS_API_URL"
      value = "https://metrics.${var.env_subdomain}.service.gov.uk"
    }

    environment_variable {
      name  = "METRICS_API_KEY"
      value = data.aws_secretsmanager_secret_version.metrics_api_key_data.secret_string
    }

    environment_variable {
      name  = "TOKEN_NAME"
      value = jsondecode(data.aws_secretsmanager_secret_version.metrics_data_publisher_tableau_data.secret_string)["TOKEN_NAME"]
    }

    environment_variable {
      name  = "TOKEN_VALUE"
      value = jsondecode(data.aws_secretsmanager_secret_version.metrics_data_publisher_tableau_data.secret_string)["TOKEN_VALUE"]
    }

    environment_variable {
      name  = "SITE_ID"
      value = jsondecode(data.aws_secretsmanager_secret_version.metrics_data_publisher_tableau_data.secret_string)["SITE_ID"]
    }

    environment_variable {
      name  = "SERVER_URL"
      value = jsondecode(data.aws_secretsmanager_secret_version.metrics_data_publisher_tableau_data.secret_string)["SERVER_URL"]
    }

    environment_variable {
      name  = "PROJECT_NAME"
      value = jsondecode(data.aws_secretsmanager_secret_version.metrics_data_publisher_tableau_data.secret_string)["PROJECT_NAME"]
    }
  }

  vpc_config {
    vpc_id             = var.backend_vpc_id
    subnets            = var.backend_subnet_ids
    security_group_ids = [aws_security_group.tableau_publication_sg.id]
  }

  source {
    type            = "GITHUB"
    location        = var.metrics_data_publisher_repository
    git_clone_depth = 1
    buildspec       = <<EOF
version: 0.2
phases:
  build:
    commands:
      - echo "Building docker image..."
      - docker build --target production -t metrics-data-publisher:latest .
      - echo "Running recover_and_publish inside the container..."
      - docker run --rm -e METRICS_API_URL -e METRICS_API_KEY -e TOKEN_NAME -e TOKEN_VALUE -e SITE_ID -e SERVER_URL -e PROJECT_NAME metrics-data-publisher:latest recover_and_publish
EOF
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "govwifi-metrics-data-publisher-group"
      stream_name = "govwifi-metrics-data-publisher-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.tableau_publication_bucket.id}/metrics-data-publisher-log"
    }
  }

}

resource "aws_security_group" "tableau_publication_sg" {
  name        = "tableau-publication-sg-${var.env}"
  description = "Security group for Tableau publication CodeBuild project"
  vpc_id      = var.backend_vpc_id

  egress {
    description = "Allow HTTPS outbound traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow HTTP outbound traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow DNS TCP outbound traffic"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow DNS UDP outbound traffic"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.env} Tableau Publication SG"
  })
}

# Trigger metrics-data-publisher daily at 05:00 UTC
resource "aws_cloudwatch_event_target" "trigger_tableau_publication" {
  rule     = aws_cloudwatch_event_rule.tableau_publication_schedule_rule.name
  arn      = aws_codebuild_project.tableau_data_source_publication.arn
  role_arn = var.govwifi_codebuild_role_arn
}

# Enable scheduled publisher in wifi-london environment only
resource "aws_cloudwatch_event_rule" "tableau_publication_schedule_rule" {
  state               = (var.env == "wifi" && var.aws_region == "eu-west-2") ? "ENABLED" : "DISABLED"
  name                = "metrics-data-publisher-scheduled-build"
  schedule_expression = "cron(0 5 * * ? *)"
}

