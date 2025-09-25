resource "aws_s3_bucket" "admin_bucket" {
  bucket        = "govwifi-${var.app_env}-admin"
  force_destroy = true

  tags = {
    Name   = "${title(var.env_name)} Admin data"
    Region = title(var.aws_region_name)
  }
}

resource "aws_s3_bucket_versioning" "admin_bucket" {
  bucket = aws_s3_bucket.admin_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "admin_bucket" {
  bucket = aws_s3_bucket.admin_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "product_page_data_bucket" {
  bucket        = "govwifi-${var.app_env}-product-page-data"
  force_destroy = true

  tags = {
    Name   = "${title(var.app_env)} Product page data"
    Region = title(var.aws_region_name)
  }
}

resource "aws_s3_bucket_public_access_block" "product_page_data_bucket" {
  bucket = aws_s3_bucket.product_page_data_bucket.id

  block_public_acls   = false
  block_public_policy = false
}


# resource "aws_s3_bucket_ownership_controls" "product_page_data_bucket" {
#   bucket = aws_s3_bucket.product_page_data_bucket.id
#   rule {
#     object_ownership = "BucketOwnerPreferred"
#   }
# }

# resource "aws_s3_bucket_acl" "product_page_data_bucket" {
#   bucket = aws_s3_bucket.product_page_data_bucket.id
#   acl    = "public-read"

#   depends_on = [aws_s3_bucket_ownership_controls.product_page_data_bucket]

}

resource "aws_s3_bucket_versioning" "product_page_data_bucket" {
  bucket = aws_s3_bucket.product_page_data_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "admin_mou_bucket" {
  bucket        = "govwifi-${var.app_env}-admin-mou"
  force_destroy = true

  tags = {
    Name   = "${title(var.env_name)} MOU documents from Admin"
    Region = title(var.aws_region_name)
  }
}

resource "aws_s3_bucket_versioning" "admin_mou_bucket" {
  bucket = aws_s3_bucket.admin_mou_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "admin_mou_bucket" {
  bucket = aws_s3_bucket.admin_mou_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "admin_bucket_policy" {
  bucket = aws_s3_bucket.admin_bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "AllowlistFetch",
  "Statement": [
    {
      "Sid": "Get Frontend Allowlist",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.admin_bucket.id}/clients.conf",
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": [
            ${join(
  ",",
  formatlist(
    "\"%s\"",
    concat(
      var.london_radius_ip_addresses,
      var.dublin_radius_ip_addresses,
    ),
  ),
)}
          ]
        }
      }
    }
  ]
}
POLICY

}

resource "aws_s3_bucket_policy" "product_page_data_bucket_policy" {
  bucket = aws_s3_bucket.product_page_data_bucket.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "ProductPageDataFetch",
    "Statement": [
        {
            "Sid": "Get Product Page Data For Objects",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion"
            ],
            "Resource": "arn:aws:s3:::${aws_s3_bucket.product_page_data_bucket.id}/*"
        },
        {
            "Sid": "Get Product Page Data For Bucket",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetBucketVersioning",
                "s3:ListBucket",
                "s3:ListBucketVersions"
            ],
            "Resource": "arn:aws:s3:::${aws_s3_bucket.product_page_data_bucket.id}"
        }
    ]
}
POLICY

}

# admin_bucket replication

resource "aws_iam_role" "admin_bucket_replication" {
  name = "admin-bucket-replication-role"

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

resource "aws_iam_policy" "admin_bucket_replication" {
  name = "admin-bucket-replication-role-policy"

  policy = <<POLICY
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
        "${aws_s3_bucket.admin_bucket.arn}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
         "s3:GetObjectVersionTagging"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.admin_bucket.arn}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.replication_admin_bucket.arn}/*"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "admin_bucket_replication" {
  role       = aws_iam_role.admin_bucket_replication.name
  policy_arn = aws_iam_policy.admin_bucket_replication.arn
}

data "aws_region" "replication" {
  provider = aws.replication
}

resource "aws_s3_bucket" "replication_admin_bucket" {
  provider = aws.replication

  bucket_prefix = "govwifi-admin-${var.env_name}-${data.aws_region.replication.name}-"

  force_destroy = true
}

resource "aws_s3_bucket_versioning" "replication_admin_bucket" {
  provider = aws.replication

  bucket = aws_s3_bucket.replication_admin_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "replication_admin_bucket" {
  provider = aws.replication
  bucket   = aws_s3_bucket.replication_admin_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_replication_configuration" "replication_admin_bucket" {
  depends_on = [
    aws_s3_bucket_versioning.admin_bucket,
    aws_s3_bucket_versioning.replication_admin_bucket
  ]

  role   = aws_iam_role.admin_bucket_replication.arn
  bucket = aws_s3_bucket.admin_bucket.id

  rule {
    id = "clients.conf"

    filter {
      prefix = "clients.conf"
    }

    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.replication_admin_bucket.arn
      storage_class = "STANDARD"
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }
}