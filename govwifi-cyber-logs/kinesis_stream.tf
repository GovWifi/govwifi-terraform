resource "aws_kinesis_stream" "cribil_log_stream" {
  name             = "${var.env}-${var.region}-cribl-cloudwatch-kinesis-stream"
  shard_count      = var.shard_count
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = "alias/aws/kinesis"

  tags = {
    Name = "CloudWatchToKinesis"
  }
}

resource "aws_cloudwatch_log_destination" "kinesis_log_destination" {
  depends_on = [aws_kinesis_stream.cribil_log_stream, aws_iam_role.logs_kinesis_role, aws_iam_policy.logs_kinesis_policy]
  name       = "kinesis-log-destination"
  role_arn   = aws_iam_role.logs_kinesis_role.arn
  target_arn = aws_kinesis_stream.cribil_log_stream.arn
}


resource "aws_cloudwatch_log_destination_policy" "kinesis_log_destination_policy" {
  destination_name = aws_cloudwatch_log_destination.kinesis_log_destination.name
  access_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : local.aws_account_id
        },
        "Action" : "logs:PutSubscriptionFilter",
        "Resource" : aws_cloudwatch_log_destination.kinesis_log_destination.arn
      }
    ]
  })
}

