resource "aws_iam_role" "govwifi_codepipeline_eventbridge_role" {
  name               = "govwifi-codepipeline-eventbridge-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service":  "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "codepipeline_eventbridge" {
  name   = "govwifi-codepipeline-global-policy"
  role   = aws_iam_role.govwifi_codepipeline_eventbridge_role.id
  policy = data.aws_iam_policy_document.codepipeline_eventbridge_policy.json
}

data "aws_iam_policy_document" "codepipeline_eventbridge_policy" {
  statement {
    sid = "StartPipelineExecution"
    actions = [
      "codepipeline:StartPipelineExecution"
    ]
    resources = [
      for name in var.deployed_app_names :
      "${aws_codepipeline.development_deploy_apps_pipeline[name].arn}"
    ]
  }
}