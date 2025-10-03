# Creates/manages KMS CMK
resource "aws_kms_key" "codepipeline_key" {
  description = "Key used across accounts Tools, Staging & Production to encrypt and decrypt S3 artifacts used in codebuild and codepipeline initially."
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Id": "CodepipelineKeyPolicy",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${local.aws_account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                  "arn:aws:iam::${local.aws_account_id}:role/${aws_iam_role.govwifi_codebuild_convert.name}",
                  "arn:aws:iam::${local.aws_account_id}:role/${aws_iam_role.govwifi_codebuild.name}"
							   ]
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow use of the key",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                                        "arn:aws:iam::${local.aws_development_account_id}:root",
										"arn:aws:iam::${local.aws_staging_account_id}:root",
								 		"arn:aws:iam::${local.aws_production_account_id}:root"
									]
            },
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey",
                "kms:List*",
                "kms:Put*",
                "kms:Update*",
                "kms:Revoke*",
                "kms:Disable*",
                "kms:Get*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow attachment of persistent resources",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                                        "arn:aws:iam::${local.aws_development_account_id}:root",
										"arn:aws:iam::${local.aws_staging_account_id}:root",
										"arn:aws:iam::${local.aws_production_account_id}:root"
									]
            },
            "Action": [
                "kms:CreateGrant",
                "kms:ListGrants",
                "kms:RevokeGrant"
            ],
            "Resource": "*",
            "Condition": {
                "Bool": {
                    "kms:GrantIsForAWSResource": "true"
                }
            }
        }
    ]
}
EOF
}

# Add an alias to the key
resource "aws_kms_alias" "codepipeline_key_alias" {
  name          = "alias/govwifi-aws-developer-tools-kms-key-terraformed"
  target_key_id = aws_kms_key.codepipeline_key.key_id
}



# Creates/manages KMS CMK FOR IRELAND REGION
resource "aws_kms_key" "codepipeline_key_ireland" {
  provider    = aws.dublin
  description = "Ireland region, key used across accounts Tools, Staging & Production to encrypt and decrypt S3 artifacts used in codebuild and codepipeline initially."
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Id": "CodepipelineKeyPolicy",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${local.aws_account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                  "arn:aws:iam::${local.aws_account_id}:role/${aws_iam_role.govwifi_codebuild_convert.name}",
                  "arn:aws:iam::${local.aws_account_id}:role/${aws_iam_role.govwifi_codebuild.name}"
							   ]
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow use of the key",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                                        "arn:aws:iam::${local.aws_development_account_id}:root",
										"arn:aws:iam::${local.aws_staging_account_id}:root",
								 		"arn:aws:iam::${local.aws_production_account_id}:root"
									]
            },
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey",
                "kms:List*",
                "kms:Put*",
                "kms:Update*",
                "kms:Revoke*",
                "kms:Disable*",
                "kms:Get*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow attachment of persistent resources",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                                        "arn:aws:iam::${local.aws_development_account_id}:root",
										"arn:aws:iam::${local.aws_staging_account_id}:root",
										"arn:aws:iam::${local.aws_production_account_id}:root"
									]
            },
            "Action": [
                "kms:CreateGrant",
                "kms:ListGrants",
                "kms:RevokeGrant"
            ],
            "Resource": "*",
            "Condition": {
                "Bool": {
                    "kms:GrantIsForAWSResource": "true"
                }
            }
        }
    ]
}
EOF
}

# Add an alias to the key
resource "aws_kms_alias" "codepipeline_key_alias_ireland" {
  provider      = aws.dublin
  name          = "alias/govwifi-aws-developer-tools-kms-key-terraformed-ireland"
  target_key_id = aws_kms_key.codepipeline_key_ireland.key_id
}
