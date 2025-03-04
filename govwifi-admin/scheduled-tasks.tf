resource "aws_iam_role" "scheduled_task" {
  name = "${var.env_name}-admin-scheduled-task-role"

  assume_role_policy = <<DOC
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
DOC

}

resource "aws_iam_role_policy" "scheduled_task" {
  name = "${var.env_name}-admin-scheduled-task-policy"
  role = aws_iam_role.scheduled_task.id

  policy = <<DOC
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ecs:RunTask",
            "Resource": "${replace(
  aws_ecs_task_definition.admin_task.arn,
  "/:\\d+$/",
  ":*",
)}"
        },
        {
          "Effect": "Allow",
          "Action": "iam:PassRole",
          "Resource": [
            "*"
          ],
          "Condition": {
            "StringLike": {
              "iam:PassedToService": "ecs-tasks.amazonaws.com"
            }
          }
        }
    ]
}
DOC

}

# rake cleanup:orphans

resource "aws_cloudwatch_event_rule" "daily_cleanup_data" {
  name                = "${var.env_name}-daily-cleanup-data"
  description         = "Triggers daily 03:15 UTC"
  schedule_expression = "cron(15 3 * * ? *)"
  is_enabled          = true
}

resource "aws_cloudwatch_event_target" "cleanup_orphan_admin_users" {
  target_id = "${var.env_name}-cleanup-orphan-admin-users"
  arn       = aws_ecs_cluster.admin_cluster.arn
  rule      = aws_cloudwatch_event_rule.daily_cleanup_data.name
  role_arn  = aws_iam_role.scheduled_task.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.admin_task.arn
    launch_type         = "FARGATE"
    platform_version    = "1.4.0"

    network_configuration {
      subnets = var.subnet_ids

      security_groups = concat(
        [aws_security_group.admin_ec2_in.id],
        [aws_security_group.admin_ec2_out.id]
      )

      assign_public_ip = true
    }
  }

  input = <<EOF
{
  "containerOverrides": [
    {
      "name": "admin",
      "command": ["bundle", "exec", "rake", "cleanup:orphans"]
    }
  ]
}
EOF

}

resource "aws_cloudwatch_event_target" "cleanup_unconfirmed_users" {
  target_id = "${var.env_name}-cleanup-unconfirmed-users"
  arn       = aws_ecs_cluster.admin_cluster.arn
  rule      = aws_cloudwatch_event_rule.daily_cleanup_data.name
  role_arn  = aws_iam_role.scheduled_task.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.admin_task.arn
    launch_type         = "FARGATE"
    platform_version    = "1.4.0"

    network_configuration {
      subnets = var.subnet_ids

      security_groups = concat(
        [aws_security_group.admin_ec2_in.id],
        [aws_security_group.admin_ec2_out.id]
      )

      assign_public_ip = true
    }
  }

  input = <<EOF
{
  "containerOverrides": [
    {
      "name": "admin",
      "command": ["bundle", "exec", "rake", "cleanup:unconfirmed"]
    }
  ]
}
EOF

}

# rake cleanup:organisation_usage

resource "aws_cloudwatch_event_rule" "daily_median_metrics" {
  name                = "${var.env_name}-daily-median-metrics"
  description         = "Triggers daily 05:15 UTC"
  schedule_expression = "cron(15 5 * * ? *)"
  is_enabled          = true
}

resource "aws_cloudwatch_event_target" "daily_median_metrics" {
  target_id = "${var.env_name}-daily-median-metrics"
  arn       = aws_ecs_cluster.admin_cluster.arn
  rule      = aws_cloudwatch_event_rule.daily_median_metrics.name
  role_arn  = aws_iam_role.scheduled_task.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.admin_task.arn
    launch_type         = "FARGATE"
    platform_version    = "1.4.0"

    network_configuration {
      subnets = var.subnet_ids

      security_groups = concat(
        [aws_security_group.admin_ec2_in.id],
        [aws_security_group.admin_ec2_out.id]
      )

      assign_public_ip = true
    }
  }

  input = <<EOF
 {
   "containerOverrides": [
     {
       "name": "admin",
       "command": ["bundle", "exec", "rake", "elasticsearch:publish_metrics"]
     }
   ]
 }
 EOF

}

# rake backup:service_emails

resource "aws_cloudwatch_event_rule" "daily_backup_service_emails" {
  name                = "${var.env_name}-daily-backup-service-emails"
  description         = "Triggers daily 03:30 UTC"
  schedule_expression = "cron(30 3 * * ? *)"
  is_enabled          = true
}

resource "aws_cloudwatch_event_target" "admin_backup_service_emails" {
  target_id = "${var.env_name}-admin-backup-service-emails"
  arn       = aws_ecs_cluster.admin_cluster.arn
  rule      = aws_cloudwatch_event_rule.daily_backup_service_emails.name
  role_arn  = aws_iam_role.scheduled_task.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.admin_task.arn
    launch_type         = "FARGATE"
    platform_version    = "1.4.0"

    network_configuration {
      subnets = var.subnet_ids

      security_groups = concat(
        [aws_security_group.admin_ec2_in.id],
        [aws_security_group.admin_ec2_out.id]
      )

      assign_public_ip = true
    }
  }

  input = <<EOF
{
  "containerOverrides": [
    {
      "name": "admin",
      "command": ["bundle", "exec", "rake", "backup:service_emails"]
    }
  ]
}
EOF

}

resource "aws_cloudwatch_event_rule" "daily_export_certificates" {
  name                = "${var.env_name}-daily-export-certificates"
  description         = "Triggers daily 22:00 UTC"
  schedule_expression = "cron(00 22 * * ? *)"
  is_enabled          = true
}

resource "aws_cloudwatch_event_target" "export_certificates" {
  target_id = "${var.env_name}-export-certificates"
  arn       = aws_ecs_cluster.admin_cluster.arn
  rule      = aws_cloudwatch_event_rule.daily_export_certificates.name
  role_arn  = aws_iam_role.scheduled_task.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.admin_task.arn
    launch_type         = "FARGATE"
    platform_version    = "1.4.0"

    network_configuration {
      subnets = var.subnet_ids

      security_groups = concat(
        [aws_security_group.admin_ec2_in.id],
        [aws_security_group.admin_ec2_out.id]
      )

      assign_public_ip = true
    }
  }

  input = <<EOF
{
  "containerOverrides": [
    {
      "name": "admin",
      "command": ["bundle", "exec", "rake", "export_certificates"]
    }
  ]
}
EOF

}
