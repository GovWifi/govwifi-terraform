resource "aws_lb" "metrics_alb" {
  name     = "metrics-alb-${var.env}"
  internal = true
  subnets  = var.backend_subnet_ids

  security_groups = [
    aws_security_group.metrics_alb_in.id,
    aws_security_group.metrics_alb_out.id,
  ]

  access_logs {
    bucket  = aws_s3_bucket.metrics_access_logs.bucket
    enabled = true
  }

  load_balancer_type = "application"

  tags = var.tags
}

resource "aws_s3_bucket" "metrics_access_logs" {
  bucket_prefix = "govwifi-metrics-access-logs-"

  tags = merge(var.tags, {
    Name = "${var.env} Metrics access logs"
  })
}

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket_public_access_block" "metrics_access_logs" {
  bucket = aws_s3_bucket.metrics_access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "metrics_logs" {
  bucket = aws_s3_bucket.metrics_access_logs.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${data.aws_elb_service_account.main.arn}"
      },
      "Action": "s3:PutObject",
      "Resource": [
        "${aws_s3_bucket.metrics_access_logs.arn}/AWSLogs/*",
        "${aws_s3_bucket.metrics_access_logs.arn}/AWSLogs"
      ]
    }
  ]
}
POLICY
}

resource "aws_alb_listener" "metrics_https" {
  load_balancer_arn = aws_lb.metrics_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.metrics_cert.certificate_arn
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    target_group_arn = aws_alb_target_group.metrics_tg.arn
    type             = "forward"
  }
}
