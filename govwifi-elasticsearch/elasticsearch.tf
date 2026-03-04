resource "aws_security_group" "elasticsearch_inbound" {
  name        = "elasticsearch-inbound"
  description = "Allow Outbound Traffic From the API"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${title(var.env_name)} Elasticsearch inbound traffic"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
}
## this needs to be migrated to resource "aws_opensearch_domain"
resource "aws_elasticsearch_domain" "govwifi_elasticsearch" {
  domain_name           = var.domain_name
  elasticsearch_version = "7.9"

  cluster_config {
    instance_type            = "t3.medium.elasticsearch"
    instance_count           = 1
    dedicated_master_enabled = false
    zone_awareness_enabled   = false
  }

  vpc_options {
    subnet_ids = [
      var.backend_subnet_id
    ]

    security_group_ids = [
      aws_security_group.elasticsearch_inbound.id,
    ]
  }

  ebs_options {
    ebs_enabled = true
    volume_size = "10"
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-PFS-2023-10"
  }

  access_policies = <<DOC
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "es:*",
      "Resource": "arn:aws:es:${var.aws_region}:${var.aws_account_id}:domain/${var.domain_name}/*"
    }
  ]
}
DOC
}

resource "aws_iam_service_linked_role" "elasticsearch" {
  aws_service_name = "es.amazonaws.com"
}
