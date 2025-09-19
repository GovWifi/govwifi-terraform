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


