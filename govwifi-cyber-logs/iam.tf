resource "aws_iam_role" "cribl_ingest" {
  name = "${var.env}-cribl-ingest-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect : "Allow",
        Principal : {
          AWS : "${var.cribl_worker_arn}"
        },
        Action : "sts:AssumeRole",
        Condition : {
          StringEquals : {
            "sts:ExternalId" : "${data.aws_secretsmanager_secret_version.cribl_external_id_val.secret_string}"
          }
        }
      }
    ]
  })

  tags = {
    Name = "cribl-ingest"
  }
}

resource "aws_iam_policy" "cribl_kinesis" {
  name        = "${var.env}-cribl-kinesis-policy"
  description = "Allows necessary access to Kinesis."
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "kinesis:GetRecords",
        "kinesis:GetShardIterator",
        "kinesis:ListShards"
      ]
      Resource = "${aws_kinesis_stream.cribil_log_stream.arn}"
    }]
  })
}


resource "aws_iam_role_policy_attachment" "attach_kinesis" {
  policy_arn = aws_iam_policy.cribl_kinesis.arn
  role       = aws_iam_role.cribl_ingest.name
}

resource "aws_iam_role" "logs_kinesis_role" {
  name = "${var.env}-kinesis-cloudwatch-logs-producer-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "logs.amazonaws.com"
        },
        "Action" : "sts:AssumeRole",
        "Condition" : {
          "StringLike" : {
            "aws:SourceArn" : "arn:aws:logs:${var.region}:${var.aws_account_id}:*"
          }
        }
      }
    ]
  })
}


resource "aws_iam_policy" "logs_kinesis_policy" {
  name        = "kinesis-cloudwatch-logs-producer-policy"
  path        = "/"
  description = "IAM policy for CloudWatch Logs to put records to Kinesis on another account."
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ],
        "Resource" : "${aws_kinesis_stream.cribil_log_stream.arn}"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "kinesis_role_policy_attachment" {
  role       = aws_iam_role.logs_kinesis_role.name
  policy_arn = aws_iam_policy.logs_kinesis_policy.arn
}
