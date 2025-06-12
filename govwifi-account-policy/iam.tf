resource "aws_iam_role" "iam_management" {
  count = (var.aws_region == "eu-west-2" ? 1 : 0)
  name  = "govwifi-iam-management-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}

EOF

}

resource "aws_iam_policy" "iam_management" {
  count = (var.aws_region == "eu-west-2" ? 1 : 0)
  name  = "GovwifiIAMUserManagment"
  path  = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:ListUsers",
        "iam:ListAccessKeys",
        "iam:GetAccessKeyLastUsed",
        "iam:UpdateAccessKey"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:*"
      ]
    }
  ]
}

EOF

}

resource "aws_iam_role_policy_attachment" "iam_management" {
  count      = (var.aws_region == "eu-west-2" ? 1 : 0)
  role       = aws_iam_role.iam_management[0].name
  policy_arn = aws_iam_policy.iam_management[0].arn
}



resource "aws_iam_policy" "govwifi_cloudwatch_readonly_policy" {
  count       = (var.env == "tools" ? 0 : 1)
  name        = "GovwifiPolicyForCloudWatchForCybersecurity"
  description = "Provides read-only access to Application Insights resources"

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "applicationinsights:Describe*",
                "applicationinsights:List*"
            ],
            "Resource": "*"
        }
    ]
  }
EOF
}

resource "aws_iam_role" "govwifi_cloudwatch_for_cybersecurity" {
  count       = (var.env == "tools" ? 0 : 1)
  name        = "GovwifiRoleForCloudWatchForCybersecurity"
  description = "Allows Kinesis Firehose and Lambda to assume CloudWatch-AppInsights role to send data to Kinesis Data Stream from Cloudwatch Logs for CyberSecurity Team."
  path        = "/"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com",
          "lambda.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

}

resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  count      = (var.env == "tools" ? 0 : 1)
  role       = aws_iam_role.govwifi_cloudwatch_for_cybersecurity[0].name
  policy_arn = aws_iam_policy.govwifi_cloudwatch_readonly_policy[0].arn
}