# --------------------------------------------------------------
# Access logs
# --------------------------------------------------------------

resource "aws_iam_role" "accesslogs_replication" {
  name = "${lower(var.product_name)}-${var.env_name}-${lower(var.aws_region_name)}-accesslogs-replication-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY

}

resource "aws_iam_policy" "accesslogs_replication" {
  name = "${lower(var.product_name)}-${lower(var.env_name)}-${lower(var.aws_region_name)}-accesslogs-replication-policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.accesslogs_bucket.arn}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersion",
        "s3:GetObjectVersionAcl"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.accesslogs_bucket.arn}/*"
      ]
    },
    {
      "Action": [
         "s3:ReplicateObject",
         "s3:ReplicateDelete"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${lower(var.product_name)}-${var.env_name}-${lower(var.backup_region_name)}-accesslogs/*"
    }
  ]
}
EOF

}

resource "aws_iam_policy_attachment" "accesslogs_replication" {
  name       = "${lower(var.product_name)}-${lower(var.env_name)}-${lower(var.aws_region_name)}-accesslogs-replication"
  roles      = [aws_iam_role.accesslogs_replication.name]
  policy_arn = aws_iam_policy.accesslogs_replication.arn
}

resource "aws_s3_bucket" "accesslogs_bucket" {
  bucket = "${lower(var.product_name)}-${var.env_name}-${lower(var.aws_region_name)}-accesslogs"

  tags = {
    Region   = title(var.aws_region_name)
    Product  = var.product_name
    Category = "Email Accesslogs"
    Name     = "Wifi Email Access Logs Bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "accesslogs_bucket" {
  bucket = aws_s3_bucket.accesslogs_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# resource "aws_s3_bucket_replication_configuration" "accesslogs_bucket" {
#   depends_on = [
#     aws_s3_bucket_versioning.accesslogs_bucket
#   ]
#
#   bucket = aws_s3_bucket.accesslogs_bucket.id
#   role   = aws_iam_role.accesslogs_replication.arn
#
#   rule {
#     id = "${lower(var.aws_region_name)}-to-${lower(var.backup_region_name)}-accesslogs-backup"
#
#     filter {
#       prefix = "${lower(var.aws_region_name)}-accesslogs-backup"
#     }
#
#     destination {
#       bucket        = "arn:aws:s3:::${lower(var.product_name)}-${lower(var.env_name)}-${lower(var.backup_region_name)}-accesslogs"
#       storage_class = "STANDARD"
#     }
#
#     delete_marker_replication {
#       status = "Enabled"
#     }
#
#     status = "Enabled"
#   }
# }

resource "aws_s3_bucket_ownership_controls" "accesslogs_bucket" {
  bucket = aws_s3_bucket.accesslogs_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "accesslogs_bucket" {
  bucket = aws_s3_bucket.accesslogs_bucket.id
  acl    = "log-delivery-write"

  depends_on = [aws_s3_bucket_ownership_controls.accesslogs_bucket]

}

resource "aws_s3_bucket_versioning" "accesslogs_bucket" {
  bucket = aws_s3_bucket.accesslogs_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "accesslogs_bucket" {
  depends_on = [aws_s3_bucket_versioning.accesslogs_bucket]

  bucket = aws_s3_bucket.accesslogs_bucket.id

  rule {
    id = "${lower(var.product_name)}-${lower(var.env_name)}-${lower(var.aws_region_name)}-accesslogs-lifecycle"

    transition {
      days          = var.accesslogs_glacier_transition_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.accesslogs_expiration_days
    }

    status = "Enabled"
  }
}
