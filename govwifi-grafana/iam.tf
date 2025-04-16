resource "aws_iam_instance_profile" "grafana_instance_profile" {
  name = "${var.aws_region}-${var.env_name}-grafana-instance"
  role = aws_iam_role.grafana_instance_role.name
}

resource "aws_iam_role" "grafana_instance_role" {
  name = "${var.aws_region}-${var.env_name}-grafana-instance"
  path = "/"

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


resource "aws_iam_role_policy_attachment" "grafana_instance_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.grafana_instance_role.id
}

resource "aws_iam_role_policy" "grafana_instance_policy" {
  name = "${var.aws_region}-${var.env_name}-grafana-instance-policy"
  role = aws_iam_role.grafana_instance_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cloudwatch:*",
        "ec2:DescribeVolumes",
        "ec2:DescribeTags"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups",
        "logs:CreateLogStream",
        "logs:CreateLogGroup",
        "logs:PutRetentionPolicy"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "ssm:StartSession",
        "Resource": [
          "arn:aws:ec2:${var.aws_region}:${var.aws_account_id}:instance/${aws_instance.grafana_instance.id}",
          "arn:aws:ssm:*:*:document/AWS-StartSSHSession"
      ],
      "Condition": {
          "BoolIfExists": {
              "ssm:SessionDocumentAccessCheck": "true"
          }
        }
    },
    {
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:grafana/credentials*"
      ],
      "Condition": {
        "DateGreaterThan": {"aws:CurrentTime": "${time_static.instance_update.rfc3339}"},
        "DateLessThan": {"aws:CurrentTime": "${timeadd(time_static.instance_update.rfc3339, "10m")}"}
      }
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "grafana_assume_role" {
  count = (var.aws_region == "eu-west-2" ? 1 : 0)
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "dlm_grafana_lifecycle_role" {
  count              = (var.aws_region == "eu-west-2" ? 1 : 0)
  name               = "grafana-dlm-lifecycle-role"
  assume_role_policy = data.aws_iam_policy_document.grafana_assume_role[0].json
}

data "aws_iam_policy_document" "grafana_dlm_lifecycle" {
  count = (var.aws_region == "eu-west-2" ? 1 : 0)
  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateSnapshot",
      "ec2:CreateSnapshots",
      "ec2:DeleteSnapshot",
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
    ]

    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:*::snapshot/*"]
  }
}

resource "aws_iam_policy" "grafana_dlm_lifecycle" {
  count  = (var.aws_region == "eu-west-2" ? 1 : 0)
  name   = "GrafanaDLMlifecyclePolicy"
  path   = "/"
  policy = data.aws_iam_policy_document.grafana_dlm_lifecycle[0].json
}

resource "aws_iam_policy_attachment" "grafana_dlm_lifecycle" {
  count      = (var.aws_region == "eu-west-2" ? 1 : 0)
  name       = aws_iam_policy.grafana_dlm_lifecycle[0].name
  roles      = [aws_iam_role.dlm_grafana_lifecycle_role[0].name]
  policy_arn = aws_iam_policy.grafana_dlm_lifecycle[0].arn
}

resource "aws_iam_role" "grafana_reboot_role" {
  name               = "${var.aws_region_name}-${var.env_name}-grafana-reboot-role"
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
resource "aws_iam_role_policy" "grafana_reboot_policy" {
  depends_on = [aws_iam_role.grafana_reboot_role]
  name       = "${var.aws_region_name}-${var.env_name}-grafana-reboot-role-policy"
  role       = aws_iam_role.grafana_reboot_role.name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "grafanaRebootPolicy",
            "Effect": "Allow",
            "Action": "ec2:RebootInstances",
            "Resource": "arn:aws:ec2:*:${var.aws_account_id}:instance/*"
        }
    ]
}
EOF

}
