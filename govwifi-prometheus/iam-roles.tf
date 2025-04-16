resource "aws_iam_instance_profile" "prometheus_instance_profile" {
  name = "${data.aws_region.current.name}-${var.env_name}-prometheus-instance-profile"
  role = aws_iam_role.prometheus_instance_role.name
}

resource "aws_iam_role" "prometheus_instance_role" {
  name = "${data.aws_region.current.name}-${var.env_name}-prometheus-instance-role"
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

resource "aws_iam_role_policy_attachment" "prometheus_instance_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.prometheus_instance_role.id
}

resource "aws_iam_role_policy" "prometheus_instance_policy" {
  name = "${data.aws_region.current.name}-${var.env_name}-prometheus-instance-policy"
  role = aws_iam_role.prometheus_instance_role.id

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
      "Effect": "Allow",
      "Action": [
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups",
        "logs:CreateLogStream",
        "logs:CreateLogGroup",
        "logs:PutRetentionPolicy"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "ssm:StartSession",
      "Resource": [
          "arn:aws:ec2:${var.aws_region}:${var.aws_account_id}:instance/${aws_instance.prometheus_instance.id}",
          "arn:aws:ssm:*:*:document/AWS-StartSSHSession"
      ],
      "Condition": {
          "BoolIfExists": {
              "ssm:SessionDocumentAccessCheck": "true"
          }
        }
    }
  ]
}
EOF

}

data "aws_iam_policy_document" "prometheus_assume_role" {
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

resource "aws_iam_role" "dlm_prometheus_lifecycle_role" {
  count              = (var.aws_region == "eu-west-2" ? 1 : 0)
  name               = "prometheus-dlm-lifecycle-role"
  assume_role_policy = data.aws_iam_policy_document.prometheus_assume_role[0].json
}

data "aws_iam_policy_document" "prometheus_dlm_lifecycle" {
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

resource "aws_iam_policy" "prometheus_dlm_lifecycle" {
  count  = (var.aws_region == "eu-west-2" ? 1 : 0)
  name   = "PrometheusDLMlifecyclePolicy"
  path   = "/"
  policy = data.aws_iam_policy_document.prometheus_dlm_lifecycle[0].json
}

resource "aws_iam_role" "prometheus_reboot_role" {
  name               = "${var.aws_region_name}-${var.env_name}-prometheus-reboot-role"
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
resource "aws_iam_role_policy" "prometheus_reboot_policy" {
  depends_on = [aws_iam_role.prometheus_reboot_role]
  name       = "${var.aws_region_name}-${var.env_name}-prometheus-reboot-role-policy"
  role       = aws_iam_role.prometheus_reboot_role.name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "prometheusRebootPolicy",
            "Effect": "Allow",
            "Action": "ec2:RebootInstances",
            "Resource": "arn:aws:ec2:*:${var.aws_account_id}:instance/*"
        }
    ]
}
EOF

}
