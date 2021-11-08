resource "aws_lb" "api_alb" {
  name     = "api-alb-${var.env_name}"
  internal = false
  count    = var.backend_elb_count
  subnets  = var.subnet_ids

  security_groups = [
    aws_security_group.api_alb_in.id,
    aws_security_group.api_alb_out.id,
  ]

  load_balancer_type = "application"

  tags = {
    Name = "api-alb-${var.env_name}"
  }
}

resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.api_alb[0].arn
  port              = "8443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.api_elb_regional[0].arn
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    target_group_arn = aws_alb_target_group.alb_target_group.arn
    type             = "forward"
  }
}

resource "aws_lb_listener_certificate" "api_elb_global" {
  count           = var.backend_elb_count
  listener_arn    = aws_alb_listener.alb_listener.arn
  certificate_arn = aws_acm_certificate.api_elb_global[0].arn

  depends_on = [aws_acm_certificate_validation.api_elb_global]
}

resource "aws_security_group" "api_alb_in" {
  name        = "loadbalancer-in"
  description = "Allow Inbound Traffic To The ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${title(var.env_name)} ALB Traffic In"
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = [for ip in var.radius_server_ips : "${ip}/32"]
  }
}

resource "aws_security_group" "api_alb_out" {
  name        = "loadbalancer-out"
  description = "Allow Outbound Traffic To The ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${title(var.env_name)} ALB Traffic Out"
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

