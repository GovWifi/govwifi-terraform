# Using custom ubuntu AMI id, as the micro size is only supported for paravirtual images.
resource "aws_instance" "management" {
  count         = var.enable_bastion
  ami           = var.bastion_ami
  instance_type = var.bastion_instance_type
  key_name      = var.bastion_ssh_key_name
  subnet_id     = aws_subnet.wifi_backend_subnet[data.aws_availability_zones.zones.names[0]].id

  vpc_security_group_ids = [
    aws_security_group.be_vpn_in.id,
    aws_security_group.be_vpn_out.id,
    aws_security_group.be_ecs_out.id,
  ]

  iam_instance_profile = aws_iam_instance_profile.bastion_instance_profile[0].id
  monitoring           = var.enable_bastion_monitoring

  depends_on = [aws_iam_instance_profile.bastion_instance_profile]

  user_data = <<DATA
Content-Type: multipart/mixed; boundary="==BOUNDARY=="
MIME-Version: 1.0

--==BOUNDARY==
MIME-Version: 1.0
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Wait for dpkg to be available
until [[ -z `sudo lsof /var/lib/dpkg/lock` ]] ; do echo -n "." >> /var/log/dpkg-wait.log; sleep 1; done
until [[ -z `sudo lsof /var/lib/apt/lists/lock` ]] ; do echo -n "." >> /var/log/apt-list-wait.log; sleep 1; done

# Fix for grub update bug https://bugs.launchpad.net/ubuntu/+source/apt/+bug/1323772
sudo rm /boot/grub/menu.lst
sudo update-grub-legacy-ec2 -y

# Wait for dpkg to be available
until [[ -z `sudo lsof /var/lib/dpkg/lock` ]] ; do echo -n "." >> /var/log/dpkg-wait.log; sleep 1; done
until [[ -z `sudo lsof /var/lib/apt/lists/lock` ]] ; do echo -n "." >> /var/log/apt-list-wait.log; sleep 1; done
sudo apt-get update -q
until [[ -z `sudo lsof /var/lib/dpkg/lock` ]] ; do echo -n "." >> /var/log/dpkg-wait.log; sleep 1; done
until [[ -z `sudo lsof /var/lib/apt/lists/lock` ]] ; do echo -n "." >> /var/log/apt-list-wait.log; sleep 1; done
# Workaround, to skip failure to update libpam-systemd and libpam-runtime. Manual update may be required.
# See https://bugs.launchpad.net/ubuntu/+source/pam/+bug/682662
sudo apt-mark hold libpam-systemd:amd64 libpam-runtime
sudo apt-get upgrade -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
until [[ -z `sudo lsof /var/lib/dpkg/lock` ]] ; do echo -n "." >> /var/log/dpkg-wait.log; sleep 1; done
until [[ -z `sudo lsof /var/lib/apt/lists/lock` ]] ; do echo -n "." >> /var/log/apt-list-wait.log; sleep 1; done
sudo apt-get install -yq --autoremove \
    mysql-client \
    htop \
    mc \
    awscli

# Allow auto-updates for everything, not just security
sudo sed -i -e 's/\/\/\t"$${distro_id}:$${distro_codename}-updates";/\t"$${distro_id}:$${distro_codename}-updates";/g' /etc/apt/apt.conf.d/50unattended-upgrades
# Install updates in the background while the machine is running
sudo sed -i -e 's/\/\/Unattended-Upgrade::InstallOnShutdown "true";/Unattended-Upgrade::InstallOnShutdown "false";/g' /etc/apt/apt.conf.d/50unattended-upgrades
# Reboot automatically (and instantly) when required
sudo sed -i -e 's/\/\/Unattended-Upgrade::Automatic-Reboot "false";/Unattended-Upgrade::Automatic-Reboot "true";/g' /etc/apt/apt.conf.d/50unattended-upgrades

# Set up periodic run of upgrades
cat <<'EOF' > ./periodic-updates-setup
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
sudo cp ./periodic-updates-setup /etc/apt/apt.conf.d/10periodic

--==BOUNDARY==
MIME-Version: 1.0
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash

sudo sed -i -e "\$a Ciphers\ aes128-ctr,aes192-ctr,aes256-ctr" /etc/ssh/sshd_config
sudo /etc/init.d/ssh reload

--==BOUNDARY==
MIME-Version: 1.0
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
# Inject the CloudWatch Logs configuration file contents
sudo cat <<'EOF' > ./initial-awslogs.conf
[general]
state_file = /var/awslogs/state/agent-state

[/var/log/syslog]
file = /var/log/syslog
log_group_name = ${var.env_name}-bastion/var/log/syslog
log_stream_name = {instance_id}
datetime_format = %b %d %H:%M:%S

[/var/log/auth.log]
file = /var/log/auth.log
log_group_name = ${var.env_name}-bastion/var/log/auth.log
log_stream_name = {instance_id}
datetime_format = %b %d %H:%M:%S

[/var/log/dmesg]
file = /var/log/dmesg
log_group_name = ${var.env_name}-bastion/var/log/dmesg
log_stream_name = {instance_id}

[/var/log/unattended-upgrades/unattended-upgrades.log]
file = /var/log/unattended-upgrades/unattended-upgrades.log
log_group_name = ${var.env_name}-bastion/var/log/unattended-upgrades/unattended-upgrades.log
log_stream_name = {instance_id}
datetime_format = %Y-%m-%d %H:%M:%S

[/var/log/cloud-init-output.log]
file = /var/log/cloud-init-output.log
log_group_name = ${var.env_name}-bastion/var/log/cloud-init-output.log
log_stream_name = {instance_id}

EOF

# Install awslogs
# Steps required are install pre-reqs for python 3.5.n, install & build python 3.5 cos awslogs script only supports python < 3.5

PYTHON_MAIN_VERSION=3.5
PYTHON_VERSION=$PYTHON_MAIN_VERSION.10

function run-until-success() {
  until $*
  do
    logger "Executing $* failed. Sleeping..."
    sleep 5
  done
}

# Install python $PYTHON_VERSION prerequisites
run-until-success sudo apt-get install --yes build-essential checkinstall
run-until-success sudo apt-get install --yes libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev

# Install python $PYTHON_VERSION source
cd /usr/src
run-until-success sudo wget https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz
sudo tar xzf Python-$PYTHON_VERSION.tgz

# Build python
cd Python-$PYTHON_VERSION/
sudo ./configure --enable-optimizations
sudo make altinstall

# Retrieve and run awslogs install script
cd /
run-until-success sudo curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O
sudo python$PYTHON_MAIN_VERSION ./awslogs-agent-setup.py -n -r ${var.aws_region} -c ./initial-awslogs.conf

--==BOUNDARY==--
DATA


  tags = {
    Name = "${title(var.env_name)} Bastion - backend (${aws_vpc.wifi_backend.id})"
    Env  = title(var.env_name)
  }
}

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
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "bastion_instance_policy_pp" {
  count = var.enable_bastion
  name  = "${var.aws_region_name}-${var.env_name}-backend-bastion-instance-policy"
  role  = aws_iam_role.bastion_instance_role[0].id
  depends_on = [
    aws_iam_role.bastion_instance_role
  ]

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

resource "aws_eip_association" "eip_assoc" {
  count       = var.enable_bastion
  instance_id = aws_instance.management[0].id
  public_ip   = var.bastion_server_ip
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
  alarm_actions      = [var.capacity_notifications_arn]
  treat_missing_data = "breaching"
}
