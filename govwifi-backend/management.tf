data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu-pro-server/images/hvm-ssd/ubuntu-jammy-22.04-amd64-pro-server-20250530"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "management" {
  count         = var.enable_bastion
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.bastion_instance_type
  key_name      = var.bastion_ssh_key_name
  subnet_id     = aws_subnet.wifi_backend_subnet[data.aws_availability_zones.zones.names[0]].id

  vpc_security_group_ids = [
    aws_security_group.be_ecs_out.id,
  ]

  iam_instance_profile = aws_iam_instance_profile.bastion_instance_profile[0].id
  monitoring           = var.enable_bastion_monitoring

  depends_on = [aws_iam_instance_profile.bastion_instance_profile]

  root_block_device {
    volume_size = 30
    tags = {
      Name = "${title(var.env_name)} Bastion Root Volume"
    }
  }

  user_data = <<DATA
#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Wait for dpkg to be available
until [ -z `sudo lsof /var/lib/dpkg/lock` ] ; do echo -n "." >> /var/log/dpkg-wait.log; sleep 1; done
until [ -z `sudo lsof /var/lib/apt/lists/lock` ] ; do echo -n "." >> /var/log/apt-list-wait.log; sleep 1; done

# Fix for grub update bug https://bugs.launchpad.net/ubuntu/+source/apt/+bug/1323772
sudo rm /boot/grub/menu.lst

# Wait for dpkg to be available
until [ -z `sudo lsof /var/lib/dpkg/lock` ] ; do echo -n "." >> /var/log/dpkg-wait.log; sleep 1; done
until [ -z `sudo lsof /var/lib/apt/lists/lock` ] ; do echo -n "." >> /var/log/apt-list-wait.log; sleep 1; done
sudo apt-get update -q
until [ -z `sudo lsof /var/lib/dpkg/lock` ] ; do echo -n "." >> /var/log/dpkg-wait.log; sleep 1; done
until [ -z `sudo lsof /var/lib/apt/lists/lock` ] ; do echo -n "." >> /var/log/apt-list-wait.log; sleep 1; done

# Workaround, to skip failure to update libpam-systemd and libpam-runtime. Manual update may be required.
# See https://bugs.launchpad.net/ubuntu/+source/pam/+bug/682662
sudo apt-mark hold libpam-systemd:amd64 libpam-runtime
sudo apt-get upgrade -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
until [ -z `sudo lsof /var/lib/dpkg/lock` ] ; do echo -n "." >> /var/log/dpkg-wait.log; sleep 1; done
until [ -z `sudo lsof /var/lib/apt/lists/lock` ] ; do echo -n "." >> /var/log/apt-list-wait.log; sleep 1; done
sudo apt-get install -yq --autoremove \
    mysql-client \
    htop \
    mc \
    awscli

# Turn on unattended upgrades
sudo dpkg-reconfigure -f noninteractive unattended-upgrades

sudo sed -i -e "\$a Ciphers\ aes128-ctr,aes192-ctr,aes256-ctr" /etc/ssh/sshd_config
sudo /etc/init.d/ssh reload

# Install the AWS Cloudwatch Agent

cd ~
wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb

# Inject the CloudWatch Logs configuration file contents, we seem to have to touch the file first

sudo touch /opt/aws/amazon-cloudwatch-agent/bin/config.json
sudo chmod 747 /opt/aws/amazon-cloudwatch-agent/bin/config.json

sudo cat <<'EOF' > /opt/aws/amazon-cloudwatch-agent/bin/config.json
{
  "agent": {
    "metrics_collection_interval": 60,
    "region": "eu-west-2",
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/syslog",
            "log_group_class": "STANDARD",
            "log_group_name": "${var.env_name}-bastion/var/log/syslog",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 30
          },
          {
            "file_path": "/var/log/auth.log",
            "log_group_class": "STANDARD",
            "log_group_name": "${var.env_name}-bastion/var/log/authlog",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 30
          },
          {
            "file_path": "/var/log/dmesg",
            "log_group_class": "STANDARD",
            "log_group_name": "${var.env_name}-bastion/var/log/dmesg",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 30
          },
          {
            "file_path": "/var/log/unattended-upgrades/unattended-upgrades.log",
            "log_group_class": "STANDARD",
            "log_group_name": "${var.env_name}-bastion/var/log/unattended-upgrades/unattended-upgrades.log",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 30
          },
          {
            "file_path": "/var/log/cloud-init-output.log",
            "log_group_class": "STANDARD",
            "log_group_name": "${var.env_name}-bastion/var/log/cloud-init-output.log",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 30
          }
        ]
      }
    }
  }
}

EOF

# Reset permissions on config
sudo chmod 744 /opt/aws/amazon-cloudwatch-agent/bin/config.json

# Start the Cloudwatch Agent
cd
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json

DATA

  tags = {
    Name = "${title(var.env_name)} Bastion - backend (${aws_vpc.wifi_backend.id})"
  }
}

locals {
  log_group_names = ["syslog", "authlog", "dmesg", "unattended-upgrades/unattended-upgrades.log", "cloud-init-output.log"]
}

# resource "aws_cloudwatch_log_group" "bastion_logs" {
#   for_each = toset([
#     for v in local.log_group_names : v
#     if var.aws_region == "eu-west-2" && var.enable_bastion == 1
#   ])
#   name              = "${var.env_name}-bastion/var/log/${each.key}"
#   retention_in_days = 30
# }


resource "aws_iam_role" "bastion_instance_role" {
  count = var.enable_bastion
  name  = "${var.aws_region_name}-${var.env_name}-backend-bastion-instance-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "bastion_instance_ssm" {
  count      = var.enable_bastion
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.bastion_instance_role[0].id
}

resource "aws_iam_role_policy" "bastion_instance_policy" {
  count      = var.enable_bastion
  name       = "${var.aws_region_name}-${var.env_name}-backend-bastion-instance-policy"
  role       = aws_iam_role.bastion_instance_role[0].id
  depends_on = [aws_iam_role.bastion_instance_role]

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "ssm:StartSession",
        "Resource": [
          "arn:aws:ec2:${var.aws_region}:${var.aws_account_id}:instance/${aws_instance.management[0].id}",
          "arn:aws:ssm:*:*:document/AWS-StartSSHSession"
      ],
      "Condition": {
          "BoolIfExists": {
              "ssm:SessionDocumentAccessCheck": "true"
          }
        }
    }
  ]
}
EOF

}

resource "aws_iam_instance_profile" "bastion_instance_profile" {
  count      = var.enable_bastion
  name       = "${var.aws_region_name}-${var.env_name}-backend-bastion-instance-profile"
  role       = aws_iam_role.bastion_instance_role[0].name
  depends_on = [aws_iam_role.bastion_instance_role]
}

resource "aws_eip" "bastion_eip" {
  count = var.enable_bastion
  vpc   = true

  tags = {
    Name = "bastion"
  }
}

resource "aws_eip_association" "eip_assoc" {
  count         = var.enable_bastion
  instance_id   = aws_instance.management[0].id
  allocation_id = aws_eip.bastion_eip[0].id
}

resource "aws_cloudwatch_metric_alarm" "bastion_statusalarm" {
  count               = var.enable_bastion
  alarm_name          = "${lower(var.env_name)}-bastion-status-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  unit                = "Count"
  threshold           = "1"

  dimensions = {
    InstanceId = aws_instance.management[0].id
  }

  alarm_description  = "This metric monitors the status of the bastion server."
  alarm_actions      = [var.critical_notifications_arn]
  treat_missing_data = "breaching"
}

resource "aws_scheduler_schedule" "reboot_bastion" {
  count      = (var.aws_region == "eu-west-2" ? 1 : 0)
  depends_on = [aws_iam_role.bastion_reboot_role[0]]
  name       = "${var.aws_region_name}-${var.env_name}-bastion-reboot"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(5 1 * * ? *)"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:rebootInstances"
    role_arn = aws_iam_role.bastion_reboot_role[0].arn

    # And this block will be passed to rebootInstances API
    input = jsonencode({
      InstanceIds = [
        aws_instance.management[0].id
      ]
    })
  }
}
