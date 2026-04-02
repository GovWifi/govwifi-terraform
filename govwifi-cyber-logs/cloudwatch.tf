resource "aws_cloudwatch_log_subscription_filter" "cloudwatch_subscription_filter" {
  for_each = local.log_groups

  name            = "${var.env}-${each.key}-cribl-subscription-filter"
  log_group_name  = each.value
  filter_pattern  = ""
  destination_arn = aws_kinesis_stream.cribil_log_stream.arn
  distribution    = "ByLogStream" # or "Random"
  role_arn        = aws_iam_role.logs_kinesis_role.arn
}