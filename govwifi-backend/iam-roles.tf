resource "aws_iam_role_policy" "ecs_instance_policy" {
  name = "${var.aws_region_name}-ecs-instance-policy-${var.env_name}"
  role = aws_iam_role.ecs_instance_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Resource": [ "*" ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups",
        "logs:PutRetentionPolicy"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics",
        "ec2:DescribeTags"
      ],
      "Resource": "*"
    }
  ]
}
EOF

}

resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.aws_region_name}-ecs-instance-role-${var.env_name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com",
          "vpc-flow-logs.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.aws_region_name}-ecs-instance-profile-${var.env_name}"
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_iam_role_policy" "ecs_service_policy" {
  name = "${var.aws_region_name}-ecs-service-policy-${var.env_name}"
  role = aws_iam_role.ecs_service_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:Describe*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets"
      ],
      "Resource": [
        "arn:aws:elasticloadbalancing:${var.aws_region}:${var.aws_account_id}:loadbalancer/wifi-backend-elb-${var.env_name}",
        "*"
      ]
    }
  ]
}
EOF

}

resource "aws_iam_role" "ecs_service_role" {
  name = "${var.aws_region_name}-ecs-service-role-${var.env_name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_role" "rds_monitoring_role" {
  name = "${var.aws_region_name}-${var.env_name}-rds-monitoring-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "monitoring.rds.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "rds_monitoring_policy" {
  depends_on = [aws_iam_role.rds_monitoring_role]
  name       = "${var.aws_region_name}-${var.env_name}-rds-monitoring-policy"
  role       = aws_iam_role.rds_monitoring_role.name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EnableCreationAndManagementOfRDSCloudwatchLogGroups",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:PutRetentionPolicy"
            ],
            "Resource": [
                "arn:aws:logs:*:*:log-group:RDS*"
            ]
        },
        {
            "Sid": "EnableCreationAndManagementOfRDSCloudwatchLogStreams",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams",
                "logs:GetLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:*:*:log-group:RDS*:log-stream:*"
            ]
        }
    ]
}
EOF

}

resource "aws_iam_role" "bastion_reboot_role" {
  count              = (var.aws_region == "eu-west-2" ? 1 : 0)
  name               = "${var.aws_region_name}-${var.env_name}-bastion-reboot-role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "scheduler.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}
resource "aws_iam_role_policy" "bastion_reboot_policy" {
  count      = (var.aws_region == "eu-west-2" ? 1 : 0)
  depends_on = [aws_iam_role.bastion_reboot_role[0]]
  name       = "${var.aws_region_name}-${var.env_name}-bastion-reboot-role-policy"
  role       = aws_iam_role.bastion_reboot_role[0].name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "bastionRebootPolicy",
            "Effect": "Allow",
            "Action": "ec2:RebootInstances",
            "Resource": "arn:aws:ec2:*:${var.aws_account_id}:instance/*"
        }
    ]
}
EOF

}

#Role for copying govwifi database backups to recovery
resource "aws_iam_role" "iam_for_recovery_database_backup" {
  count = var.recovery_backups_enabled ? 1 : 0
  name  = "govwifi-recovery-database-backup"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "s3.amazonaws.com",
                    "batchoperations.s3.amazonaws.com"
                ]
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "iam_for_recovery_database_backup" {
  count = var.recovery_backups_enabled ? 1 : 0
  name   = "govwifi-recovery-database-backup"
  role   = aws_iam_role.iam_for_recovery_database_backup[0].id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "SourceBucketPermissions",
            "Effect": "Allow",
            "Action": [
                "s3:GetObjectVersionForReplication",
                "s3:GetObjectVersionTagging",
                "s3:GetObjectVersionAcl",
                "s3:GetObjectRetention",
                "s3:GetObjectLegalHold",
                "s3:ListBucket",
                "s3:GetReplicationConfiguration",
                "s3:CreateJob"
            ],
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.rds_mysql_backup_bucket[0].id}",
                "arn:aws:s3:::${aws_s3_bucket.rds_mysql_backup_bucket[0].id}/*"
            ]
        },
        {
            "Sid": "DestinationBucketPermissions",
            "Effect": "Allow",
            "Action": [
                "s3:ReplicateObject",
                "s3:ReplicateDelete",
                "s3:ReplicateTags",
                "s3:ObjectOwnerOverrideToBucketOwner",
                "s3:GetBucketVersioning",
                "s3:PutBucketVersioning",
                "s3:CreateJob"
            ],
            "Resource": [
                "arn:aws:s3:::govwifi-database-backups",
                "arn:aws:s3:::govwifi-database-backups/*"
            ]
        },
        {
            "Sid": "KMSPermissions",
            "Effect": "Allow",
            "Action": [
                "kms:Encrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "arn:aws:kms:eu-west-2:${data.aws_secretsmanager_secret_version.recovery_account[0].secret_string}:key/${data.aws_secretsmanager_secret_version.recovery_kms_key[0].secret_string}"
        },
        {
            "Effect": "Allow",
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "arn:aws:iam::${var.aws_account_id}:role/${aws_iam_role.iam_for_recovery_database_backup[0].id}"
        }
    ]
}
EOF

depends_on = [ 
        aws_iam_role_policy.iam_for_recovery_database_backup[0]
     ]

}
