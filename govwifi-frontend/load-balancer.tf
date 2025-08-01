resource "aws_lb" "main" {
  name               = "frontend"
  load_balancer_type = "network"

  enable_cross_zone_load_balancing = false

  dynamic "subnet_mapping" {
    for_each = [for subnet in aws_subnet.wifi_frontend_subnet : subnet.id]
    iterator = subnet_id

    content {
      subnet_id     = subnet_id.value
      allocation_id = aws_eip.radius_eips[subnet_id.key].id
    }
  }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "1812"
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_lb_target_group" "main" {
  name        = "frontend"
  port        = 1812
  protocol    = "UDP"
  vpc_id      = aws_vpc.wifi_frontend.id
  target_type = "ip"

  health_check {
    protocol = "HTTP"
    path     = "/"
    port     = 3000

    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  stickiness {
    type = "source_ip"
  }
}
