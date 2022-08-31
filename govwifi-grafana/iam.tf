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
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "grafana_instance_policy" {
  name = "${var.aws_region}-${var.env_name}-grafana-instance-policy"
  role = aws_iam_role.grafana_instance_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
  ]
}
EOF

}
