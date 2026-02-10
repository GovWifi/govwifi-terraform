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
resource "aws_instance" "grafana_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.small"
  key_name      = var.ssh_key_name
  subnet_id     = var.backend_subnet_ids[0]
  user_data = templatefile("${path.module}/user_data.sh",
    {
      grafana_log_group       = "${var.env_name}-grafana-log-group",
      grafana_admin           = local.grafana_admin,
      google_client_secret    = local.google_client_secret,
      google_client_id        = local.google_client_id,
      grafana_server_root_url = local.grafana_server_root_url,
      grafana_device_name     = var.grafana_device_name,
      grafana_docker_version  = var.grafana_docker_version
    }
  )

  disable_api_termination = false
  ebs_optimized           = false

  vpc_security_group_ids = [
    aws_security_group.grafana_ec2_in.id,
    aws_security_group.grafana_ec2_out.id,
  ]

  iam_instance_profile = aws_iam_instance_profile.grafana_instance_profile.id

  tags = {
    Name = "${title(var.env_name)} Grafana-Server"
  }

  root_block_device {
    volume_size = 30
    encrypted   = true
    tags = {
      Name = "${title(var.env_name)} Grafana Root Volume"
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [volume_tags, ami] ## comment out ami from ignore_changes and run terraform apply to update, then add it back to ignore_changes to prevent future updates when a new AMI is released.
  }
}

resource "time_static" "instance_update" {
  triggers = {
    # Save the time that the instance is created, so it only changes/updates upon new instance creatation.
    instance_id = aws_instance.grafana_instance.id
  }
}

resource "aws_ebs_volume" "grafana_ebs" {
  size              = 40
  encrypted         = true
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.env_name} Grafana volume"
  }
}

resource "aws_volume_attachment" "grafana_ebs_attach" {
  depends_on  = [aws_ebs_volume.grafana_ebs]
  device_name = var.grafana_device_name
  volume_id   = aws_ebs_volume.grafana_ebs.id
  instance_id = aws_instance.grafana_instance.id
}

resource "aws_scheduler_schedule" "reboot_grafana" {
  depends_on = [aws_iam_role.grafana_reboot_role]
  name       = "${var.aws_region_name}-${var.env_name}-grafana-reboot"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(5 1 * * ? *)"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:rebootInstances"
    role_arn = aws_iam_role.grafana_reboot_role.arn

    # And this block will be passed to rebootInstances API
    input = jsonencode({
      InstanceIds = [
        aws_instance.grafana_instance.id
      ]
    })
  }
}
