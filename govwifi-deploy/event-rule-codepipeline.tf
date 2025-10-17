resource "aws_cloudwatch_event_rule" "S3_source_update_rule" {
  for_each    = toset(var.deployed_app_names)
  name        = "codepipeline_s3_source_rule_${each.key}"
  description = "Event rule to monitor the /source/${each.key} directory for updates, then start the codepipeline job"
  state       = "ENABLED"
  event_pattern = jsonencode(
    {
      "source" : ["aws.s3", "uk.gov.service.wifi"],
      "detail-type" : ["Object Created"],
      "detail" : {
        "bucket" : {
          "name" : [aws_s3_bucket.codepipeline_bucket.id]
        },
        "object" : {
          "key" : [{ "prefix" : "${local.s3_source_dir}/${each.key}/" }]
        }
      }
  })
}

# resource "aws_cloudwatch_event_target" "S3_source_update_target" {
#   for_each  = toset(var.deployed_app_names)
#   rule      = aws_cloudwatch_event_rule.S3_source_update_rule[each.key].name
#   target_id = "SendEventToCodePipeline_${each.key}"
#   arn       = aws_codepipeline.alpaca_deploy_apps_pipeline[each.key].arn
#   role_arn  = aws_iam_role.govwifi_codepipeline_eventbridge_role.arn
# }