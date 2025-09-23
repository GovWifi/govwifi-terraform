provider "aws" {
  alias  = "eu-west-1"
  region = "eu-west-1"
}

data "aws_kms_key" "kms_s3_london" {
  # These values are only needed for the bucket replication. Therefore this should only run in London
  count  = "${lower(var.aws_region_name)}" == "london" ? 1 : 0
  key_id = "alias/aws/s3"
}

data "aws_kms_key" "kms_s3_dublin" {
  # These values are only needed for the bucket replication. Therefore this should only run in London, but refers to values in eu-west-1 (ireland)
  count    = "${lower(var.aws_region_name)}" == "london" ? 1 : 0
  provider = aws.eu-west-1
  key_id   = "alias/aws/s3"
}

data "aws_ssm_parameter" "dublin_bucket_name" {
  # These values are only needed for the bucket replication.
  # Therefore this should only run in London, but refers to values in eu-west-1 (ireland)
  count      = "${lower(var.aws_region_name)}" == "london" ? 1 : 0
  provider   = aws.eu-west-1
  name       = "/govwifi-terraform/frontend-certs-bucket"
  depends_on = [aws_s3_bucket.frontend_cert_bucket]
}

resource "aws_s3_bucket" "frontend_cert_bucket" {
  bucket_prefix = "frontend-cert-${lower(var.aws_region_name)}-"

  tags = {
    Name   = "${title(var.env_name)} Frontend certs"
    Region = title(var.aws_region_name)
  }
}

resource "aws_s3_bucket_public_access_block" "frontend_cert_bucket" {
  bucket = aws_s3_bucket.frontend_cert_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend_cert_bucket" {
  bucket = aws_s3_bucket.frontend_cert_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "frontend_cert_bucket" {
  bucket = aws_s3_bucket.frontend_cert_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_ssm_parameter" "frontend_cert_bucket" {
  name        = "/govwifi-terraform/frontend-certs-bucket"
  description = "Name of the frontend-certs bucket for ${var.aws_region_name}"
  type        = "String"
  value       = aws_s3_bucket.frontend_cert_bucket.bucket
}

resource "aws_iam_policy" "govwifi_frontend_cert_bucket_access" {
  name = "govwifi-sync-cert-access-${lower(var.aws_region_name)}"

  path        = "/"
  description = "Allows govwifi-deploy-pipeline to write to the cert bucket."

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "govwifiSyncCertAccess",
            "Effect": "Allow",
            "Action": "s3:PutObject",
            "Resource": [
                "${aws_s3_bucket.frontend_cert_bucket.arn}/*"
            ]
        }
    ]
}
POLICY
}


resource "aws_s3_bucket_replication_configuration" "cert_replication_london_to_dublin" {
  # Must have bucket versioning enabled first
  count      = "${lower(var.aws_region_name)}" == "london" ? 1 : 0
  depends_on = [aws_s3_bucket_versioning.frontend_cert_bucket]

  role   = aws_iam_role.s3_replication_role[0].arn
  bucket = aws_s3_bucket.frontend_cert_bucket.id

  rule {
    id = "Certificate replication"

    filter {
      prefix = "trusted_certificates/"
    }

    delete_marker_replication {
      status = "Enabled"
    }

    status = "Enabled"

    source_selection_criteria {
      replica_modifications {
        status = "Enabled"
      }
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = "arn:aws:s3:::${data.aws_ssm_parameter.dublin_bucket_name[0].value}"
      storage_class = "STANDARD"

      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }

      metrics {
        event_threshold {
          minutes = 15
        }
        status = "Enabled"
      }

      encryption_configuration {
        replica_kms_key_id = data.aws_kms_key.kms_s3_dublin[0].arn
      }

    }
  }
}

resource "aws_iam_user_policy_attachment" "govwifi_sync_cert_access_policy_attachment" {
  user       = "govwifi-deploy-pipeline" # TODO This should reference the resource
  policy_arn = aws_iam_policy.govwifi_frontend_cert_bucket_access.arn
}
