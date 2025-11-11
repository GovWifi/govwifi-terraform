resource "aws_iam_role" "cribl_ingest" {
  name = "cribl-ingest"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect : "Allow",
        Principal : {
          AWS : var.cribl_worker_arn
        },
        Action : "sts:AssumeRole",
        Condition : {
          StringEquals : {
            "sts:ExternalId" : random_uuid.external_id.result
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
  name        = "cribl-kinesis-policy"
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
      Resource = "*"
    }]
  })
}


resource "aws_iam_role_policy_attachment" "attach_kinesis" {
  policy_arn = aws_iam_policy.cribl_kinesis.arn
  role       = aws_iam_role.cribl_ingest.name
}