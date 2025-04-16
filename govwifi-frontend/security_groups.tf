# ECS Endpoint addresses

resource "aws_security_group" "fe_ecs_out" {
  name        = "fe-ecs-out"
  description = "Allow the ECS agent to talk to the ECS endpoints"
  vpc_id      = aws_vpc.wifi_frontend.id

  tags = {
    Name = "${title(var.env_name)} Frontend ECS out"
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    # NTP
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Traffic from Prometheus server in London

resource "aws_security_group" "fe_prometheus_in" {
  name        = "fe-prometheus-in"
  description = "Allow inbound traffic from Prometheus server in London"
  vpc_id      = aws_vpc.wifi_frontend.id

  tags = {
    Name = "${title(var.env_name)} Frontend Prometheus in"
  }

  ingress {
    from_port = 9812
    to_port   = 9812
    protocol  = "tcp"

    cidr_blocks = distinct([
      "${var.prometheus_ip_ireland}/32",
      "${var.prometheus_ip_london}/32"
    ])
  }
}

# API access from the RADIUS servers

resource "aws_security_group" "fe_radius_out" {
  name        = "fe-radius-out"
  description = "Allow outbound API calls from the RADIUS servers"
  vpc_id      = aws_vpc.wifi_frontend.id

  tags = {
    Name = "${title(var.env_name)} Frontend RADIUS out"
  }

  # As the frontend servers need to talk across regions, we let this be open.
  # We should look into VPC peering at some point in the future.
  # This also inadvertently gives access to the S3 bucket.
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 9812
    to_port     = 9812
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound data to Prometheus server"
  }
}

# RADIUS traffic to the RADIUS servers

resource "aws_security_group" "fe_radius_in" {
  name        = "fe-radius-in"
  description = "Allow inbound API calls to the RADIUS servers"
  vpc_id      = aws_vpc.wifi_frontend.id

  tags = {
    Name = "${title(var.env_name)} Frontend RADIUS in"
  }

  ingress {
    description = "Radius server"
    from_port   = 1812
    to_port     = 1812
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Radius accounting"
    from_port   = 1813
    to_port     = 1813
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow route53 healthcheck"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = distinct(data.aws_ip_ranges.route53_healthcheck.cidr_blocks)
  }

  ingress {
    description = "Allow route53 healthcheck"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = distinct(data.aws_ip_ranges.route53_healthcheck.cidr_blocks)
  }

  ingress {
    description = "Allow FreeRadius Log Exporter in"
    from_port   = 9812
    to_port     = 9812
    protocol    = "tcp"
    cidr_blocks = distinct(var.radius_cidr_blocks)
  }
}

data "aws_ip_ranges" "route53_healthcheck" {
  services = ["route53_healthchecks"]

  # Depending on AWS internals, healthchecks can come from region
  # specific IP ranges, or a global range, and this can vary between
  # AWS accounts.
  #
  # Since there isn't an obvious way of allowing the relevant set of
  # IP ranges in each account, allow all of the potential ranges
  regions = ["global", "eu-west-1", "us-east-1", "us-west-1"]
}

resource "aws_security_group" "load_balanced_frontend_service" {
  name        = "load-balanced-frontend-service"
  description = "Security group for the load balanced frontend service"
  vpc_id      = aws_vpc.wifi_frontend.id
  tags = {
    Name = "${title(var.env_name)} Frontend service"
  }

  egress {
    description = "Permit traffic to AWS services"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # TODO This could probably be the subnet ranges
  }

  egress {
    description = "Permit traffic to the authentication and logging APIs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"

    # TODO This could be replaced by the relevant security groups
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "RADIUS traffic"
    from_port   = 1812
    to_port     = 1812
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "RADIUS traffic"
    from_port   = 1812
    to_port     = 1812
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Healthcheck requests from load balancer"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    description = "Allow scraping Prometheus metrics"

    from_port = 9812
    to_port   = 9812
    protocol  = "tcp"

    cidr_blocks = distinct([
      "${var.prometheus_ip_ireland}/32",
      "${var.prometheus_ip_london}/32"
    ])
  }

  ingress {
    description = "Allow scraping Prometheus metrics from the fargate cluster"

    from_port = 9812
    to_port   = 9812
    protocol  = "tcp"

    security_groups = [var.prometheus_security_group_id]
  }

  egress {
    from_port   = 9812
    to_port     = 9812
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound data to Prometheus server"
  }
}

resource "aws_security_group" "vpc_endpoints" {
  name        = "frontend_vpc_endpoints"
  description = "Permit traffic to the frontend VPC endpoints"
  vpc_id      = aws_vpc.wifi_frontend.id

  tags = {
    Name = "${title(var.env_name)} Frontend VPC Endpoints"
  }

  ingress {
    description = "ECS Cluster"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"

    security_groups = [
      aws_security_group.load_balanced_frontend_service.id,
      aws_security_group.fe_ecs_out.id
    ]
  }

  ingress {
    description = "Allow HTTPS to AWS Service CW"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
}
