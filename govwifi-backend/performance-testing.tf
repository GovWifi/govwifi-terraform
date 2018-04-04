resource "aws_instance" "performance-testing" {
  ami                    = "${var.performance-ami}"
  instance_type          = "${var.performance-instance-type}"
  key_name               = "${var.performance-ssh-key-name}"
  subnet_id              = "${aws_subnet.wifi-backend-subnet.0.id}"
  vpc_security_group_ids = ["${var.mgt-sg-list}", "${var.performance-sg-list}"]
  iam_instance_profile   = "${aws_iam_instance_profile.performance-instance-profile.id}"
  monitoring             = 0

  depends_on = [
    "aws_iam_instance_profile.performance-instance-profile",
  ]

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
# Workaround, to skip failure to update libpam-systemd. Manual update may be required.
sudo apt-mark hold libpam-systemd:amd64
sudo apt-get upgrade -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
until [[ -z `sudo lsof /var/lib/dpkg/lock` ]] ; do echo -n "." >> /var/log/dpkg-wait.log; sleep 1; done
until [[ -z `sudo lsof /var/lib/apt/lists/lock` ]] ; do echo -n "." >> /var/log/apt-list-wait.log; sleep 1; done
sudo apt-get install -yq --autoremove \
    ruby-full \
    htop \
    mc
DATA
}

resource "aws_iam_role" "performance-instance-role" {
  name = "${var.aws-region-name}-${var.Env-Name}-backend-performance-instance-role"

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

resource "aws_iam_instance_profile" "performance-instance-profile" {
  name       = "${var.aws-region-name}-${var.Env-Name}-backend-performance-instance-profile"
  role       = "${aws_iam_role.performance-instance-role.name}"
  depends_on = ["aws_iam_role.performance-instance-role"]
}

resource "aws_eip_association" "eip_assoc" {
  instance_id = "${aws_instance.performance.id}"
  public_ip   = "${replace(var.performance-server-ip, "/32", "")}"
}
