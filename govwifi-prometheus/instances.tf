data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu-pro-server/images/hvm-ssd/ubuntu-jammy-22.04-amd64-pro-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# The element() function used in subnets wraps around when the index is over the number of elements
# eg. in the 4th iteration the value returned will be the 1st, if there are only 3 elements in the list.
resource "aws_instance" "prometheus_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.small"
  key_name      = var.ssh_key_name
  subnet_id     = var.wifi_frontend_subnet[0]
  user_data = templatefile("${path.module}/user_data.sh",
    {
      data_volume_size     = var.prometheus_volume_size,
      prometheus-log-group = "${var.env_name}-prometheus-log-group",
      prometheus_config = templatefile("${path.module}/prometheus.yml",
        {
          london-radius-ip-addresses-one   = element(var.london_radius_ip_addresses, 0),
          london-radius-ip-addresses-two   = element(var.london_radius_ip_addresses, 1),
          london-radius-ip-addresses-three = element(var.london_radius_ip_addresses, 2),
          dublin-radius-ip-addresses-one   = element(var.dublin_radius_ip_addresses, 0),
          dublin-radius-ip-addresses-two   = element(var.dublin_radius_ip_addresses, 1),
          dublin-radius-ip-addresses-three = element(var.dublin_radius_ip_addresses, 2)
        }
      ),
      prometheus_startup = templatefile("${path.module}/prometheus-govwifi", {})
    }
  )
  disable_api_termination = false
  ebs_optimized           = false
  monitoring              = false

  vpc_security_group_ids = [
    aws_security_group.prometheus.id
  ]

  iam_instance_profile = aws_iam_instance_profile.prometheus_instance_profile.id

  tags = {
    Name = "${title(var.env_name)} Prometheus-Server"
  }

  root_block_device {
    volume_size = 30
    encrypted   = true
    tags = {
      Name = "${title(var.env_name)} Prometheus Root Volume"
    }
  }

  lifecycle {
    create_before_destroy = true

    ignore_changes = [volume_tags, ami] ## comment out ami from ignore_changes and run terraform apply to update, then add it back to ignore_changes to prevent future updates when a new AMI is released.
  }
}

data "aws_subnet" "main" {
  id = var.wifi_frontend_subnet[0]
}

resource "aws_ebs_volume" "prometheus_ebs" {
  size              = 40
  encrypted         = true
  availability_zone = data.aws_subnet.main.availability_zone

  tags = {
    Name = "${var.env_name} Prometheus volume"
  }
}

resource "aws_volume_attachment" "prometheus_ebs_attach" {
  depends_on  = [aws_ebs_volume.prometheus_ebs]
  device_name = "/dev/xvdp"
  volume_id   = aws_ebs_volume.prometheus_ebs.id
  instance_id = aws_instance.prometheus_instance.id
}

resource "aws_eip" "eip" {
  vpc = true

  tags = {
    Name = "prometheus"
  }
}

resource "aws_eip_association" "prometheus_eip_assoc" {
  instance_id   = aws_instance.prometheus_instance.id
  allocation_id = aws_eip.eip.id
}

resource "aws_scheduler_schedule" "reboot_prometheus" {
  depends_on = [aws_iam_role.prometheus_reboot_role]
  name       = "${var.aws_region_name}-${var.env_name}-prometheus-reboot"


  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(5 1 * * ? *)"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:rebootInstances"
    role_arn = aws_iam_role.prometheus_reboot_role.arn

    # And this block will be passed to rebootInstances API
    input = jsonencode({
      InstanceIds = [
        aws_instance.prometheus_instance.id
      ]
    })
  }
}

