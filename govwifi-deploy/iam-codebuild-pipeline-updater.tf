data "aws_iam_policy_document" "testing-codepipeline_updater_policy" {
  statement {
    sid = "UpdateStartPipelines"
    actions = [
      "codepipeline:StartPipelineExecution",
      "codepipeline:GetPipeline",
      "codepipeline:GetPipelineState",
      "codepipeline:ListPipelines",
      "codepipeline:UpdatePipeline",
      "codepipeline:StartPipelineExecution"
    ]
    resources = [
      for item in setproduct(var.test_app_pipeline, ["", "/*"]) :
      "${aws_codepipeline.testing_dev_apps_pipeline[item[0]].arn}${item[1]}"
    ]
  }
  ## Ridiculously, updating the pipeline means all the steps have to be validated so we have to pass permissions to it for both accounts, else it fails.
  statement {
    sid     = "AllowPassCodePipelineRole"
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      "${aws_iam_role.govwifi_codepipeline_global_role.arn}",
      "arn:aws:iam::${local.aws_alpaca_account_id}:role/govwifi-codebuild-role"
    ]
  }
}

# Create the IAM policy from the document.
resource "aws_iam_policy" "testing-codebuild_pipeline_updater_policy" {
  name        = "CodeBuild-CodePipeline-Updater-Policy"
  path        = "/"
  description = "Allows a CodeBuild project to update and start a specific CodePipeline."
  policy      = data.aws_iam_policy_document.testing-codepipeline_updater_policy.json
}

# Attach the new policy to the existing CodeBuild role.
resource "aws_iam_role_policy_attachment" "testing-codebuild_updater_attachment" {
  role       = aws_iam_role.govwifi_codebuild.name
  policy_arn = aws_iam_policy.testing-codebuild_pipeline_updater_policy.arn
}
