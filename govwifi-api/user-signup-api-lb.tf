resource "aws_lb" "user_signup_api" {
  count    = var.user_signup_enabled
  name     = "user-signup-api-${var.env_name}"
  internal = false
  subnets  = var.subnet_ids

  security_groups = concat(
    [aws_security_group.api_alb_in.id],
    [aws_security_group.api_alb_out.id],
    aws_security_group.user_signup_api_lb_in.*.id
  )

  load_balancer_type         = "application"
  drop_invalid_header_fields = true
  tags = {
    Name = "user-signup-api-${var.env_name}"
  }
}

resource "aws_lb_listener" "user_signup_api" {
  count             = var.user_signup_enabled
  load_balancer_arn = aws_lb.user_signup_api[0].arn
  port              = "8443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.user_signup_api_global[0].arn
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    target_group_arn = aws_alb_target_group.user_signup_api_tg[0].arn
    type             = "forward"
  }
}

resource "aws_lb_listener_certificate" "user_signup_api_regional" {
  count           = var.user_signup_enabled
  listener_arn    = aws_lb_listener.user_signup_api[0].arn
  certificate_arn = aws_acm_certificate.user_signup_api_regional[0].arn

  depends_on = [aws_acm_certificate_validation.user_signup_api_regional]
}

