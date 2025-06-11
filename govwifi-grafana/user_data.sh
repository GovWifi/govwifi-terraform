#!/bin/bash

# set -ueo pipefail

logger 'Govwifi Grafana User Data Script - Starting'
echo "Govwifi Grafana User Data Script - Starting"

echo "Echo message to see if this works"

export DEBIAN_FRONTEND=noninteractive

# set some vars frequently used but not passed by terraformed to make script easy to change if needed
#File system format
drive_format="ext4"
#path for where docker keeps its volumes that we need to make persistent
docker_volumes_folder=/var/lib/docker/volumes
#folder where the EBS volume will be mounted
drive_mount_point=/mnt/grafana-persistent
#Symlink location that will be linked to the $docker_volumes_folder
symlink_folder=$drive_mount_point/volumes

function run-until-success() {
  until $*
  do
    logger -s "Executing $* failed. Sleeping..."
    sleep 5
  done
}

# Apt - Make sure everything is up to date
run-until-success apt-get update  --yes
run-until-success apt-get upgrade --yes

# Turn on unattended upgrades
dpkg-reconfigure -f noninteractive unattended-upgrades

# We want to make sure that the journal does not write to syslog
# This would fill up the disk, with logs we already have in the journal
logger "Ensure journal does not write to syslog"
mkdir -p /etc/systemd/journald.conf.d/
cat <<JOURNAL > /etc/systemd/journald.conf.d/override.conf
[Journal]
SystemMaxUse=2G
RuntimeMaxUse=2G
ForwardToSyslog=no
ForwardToWall=no
JOURNAL

systemctl daemon-reload
systemctl restart systemd-journald

# Use Amazon NTP
# An implementation of Network Time Protocol (NTP). It can synchronise the system clock with NTP servers
logger 'Installing and configuring chrony'
run-until-success apt-get install --yes chrony
sed '/pool/d' /etc/chrony/chrony.conf \
| cat <(echo "server 169.254.169.123 prefer iburst") - > /tmp/chrony.conf
echo "allow 127/8" >> /tmp/chrony.conf
mv /tmp/chrony.conf /etc/chrony/chrony.conf
systemctl restart chrony

# Install the AWS Cloudwatch Agent
cd ~
run-until-success wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb

# Inject the CloudWatch Logs configuration file contents

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
						"log_group_name": "${grafana_log_group}",
						"log_stream_name": "{instance_id}-syslog",
						"retention_in_days": 30
					},
					{
						"file_path": "/var/log/auth.log",
						"log_group_class": "STANDARD",
						"log_group_name": "${grafana_log_group}",
						"log_stream_name": "{instance_id}-auth.log",
						"retention_in_days": 30
					},
					{
						"file_path": "/var/log/dmesg",
						"log_group_class": "STANDARD",
						"log_group_name": "${grafana_log_group}",
						"log_stream_name": "{instance_id}-dmesg",
						"retention_in_days": 30
					},
					{
						"file_path": "/var/log/unattended-upgrades/unattended-upgrades.log",
						"log_group_class": "STANDARD",
						"log_group_name": "${grafana_log_group}",
						"log_stream_name": "{instance_id}-unattended-upgrades.log",
						"retention_in_days": 30
					},
					{
						"file_path": "/var/log/cloud-init-output.log",
						"log_group_class": "STANDARD",
						"log_group_name": "${grafana_log_group}",
						"log_stream_name": "{instance_id}-cloud-init-output.log",
						"retention_in_days": 30
					}
				]
			}
		}
	}
}
EOF

# Start the Cloudwatch Agent
cd
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json

logger 'Installing awscli with apt-get'
run-until-success apt-get install --yes awscli

# Install Docker and Send Logs to CloudWatch
logger 'Installing and configuring docker'
mkdir -p /etc/systemd/system/docker.service.d
run-until-success apt-get install --yes docker.io
cat <<EOF > /etc/systemd/system/docker.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --log-driver "local"
EOF

# Start and then stop systemctl daemon to do some housekeeping (mount folders etc)
logger "Starting docker";
run-until-success systemctl start docker
logger "Stopping docker";
run-until-success systemctl stop docker

# format drive if needed and mount to mount point
if [ "$(lsblk --noheadings --output FSTYPE ${grafana_device_name})" != "$drive_format" ]; then
  logger "Formatting blank drive ${grafana_device_name} to $drive_format"
  run-until-success mkfs.$drive_format ${grafana_device_name};
fi

if [ ! -d $drive_mount_point ]; then
  logger "Making mount point '$drive_mount_point'";
  run-until-success mkdir -p $drive_mount_point;
fi

# write a line to /etc/fstab so the folder is mounted upon reboot
logger "Writing mount line to /etc/fstab";
run-until-success echo "${grafana_device_name}  $drive_mount_point $drive_format defaults  0 0" >> /etc/fstab

# now mount the drive as set in /etc/fstab
logger "Mounting '$drive_mount_point'";
run-until-success mount $drive_mount_point;

if [ ! -d $symlink_folder ]; then
  logger "Moving docker volumes folder to persistent folder '$symlink_folder' as not currently present";
  run-until-success mv $docker_volumes_folder $symlink_folder;
fi

# go in here if the symlink_folder is not there as a symlink
if [ ! -L $docker_volumes_folder ]; then
  # go in here if the symlink_folder IS there and is a normal folder
  logger "'$docker_volumes_folder' does not exist as a symlink";
  if [ -d $docker_volumes_folder ]; then
    # remove the old folder (may need to copy contents out if any file missing post install)
    logger "'$docker_volumes_folder' does exist as a folder - removing";
    run-until-success rm -fr $docker_volumes_folder;
  fi
  # now its removed we need to symlink the volumes folder from the mounted EBS volume
  logger "Linking '$symlink_folder' to '$docker_volumes_folder'";
  run-until-success ln -s $symlink_folder $docker_volumes_folder;
fi

# Reload and start docker
logger "Reloading systemctl and enabling docker";
run-until-success systemctl daemon-reload
run-until-success systemctl enable --now docker

# If not already there create Docker volumes
if [ -d $docker_volumes_folder/grafana-etc ]; then
  logger "docker image for grafana-etc already present"
else
  logger "Creating docker image for grafana-etc"
  run-until-success docker volume create grafana-etc
fi

if [ -d $docker_volumes_folder/grafana ]; then
  logger "docker image for grafana already present"
else
  logger "Creating docker image for grafana"
  run-until-success docker volume create grafana
fi

# pull the Grafana Docker image 
logger "Pulling the grafana docker image for version ${grafana_docker_version}"
run-until-success docker pull grafana/grafana:${grafana_docker_version}

# get passwords and secrets
GRAFANA_PW=$(aws secretsmanager get-secret-value --secret-id ${grafana_admin} --region eu-west-2 --query SecretString --output text | cut -d, -f1 | cut -d: -f2 | tr -d \")
# run Grafana Docker image
logger "Starting docker for Grafana";
run-until-success docker run \
	--log-driver=awslogs \
	--log-opt awslogs-create-group=true \
	--log-opt awslogs-group=${grafana_log_group} \
	--log-opt awslogs-stream=grafana-docker-logs \
	--interactive \
	--detach \
	--restart=always \
	--publish=3000:3000 \
	--name=grafana \
	--user=root \
	--volume=grafana:/var/lib/grafana \
	--volume=grafana-etc:/etc/grafana \
	--env GF_SERVER_ROOT_URL=${grafana_server_root_url} \
	--env GF_SERVER_HTTP_ADDR=0.0.0.0 \
	--env GF_AUTH_BASIC_ENABLED=true \
	--env GF_SECURITY_ADMIN_USER=admin\
	--env GF_SECURITY_ADMIN_PASSWORD=$GRAFANA_PW \
	--env GF_SECURITY_COOKIE_SECURE=true \
	--env GF_SESSION_COOKIE_SECURE=true \
	--env GF_AUTH_GOOGLE_ENABLED=true \
	--env GF_AUTH_GOOGLE_ALLOW_SIGN_UP=true \
	--env GF_AUTH_GOOGLE_ALLOWED_DOMAINS=digital.cabinet-office.gov.uk \
	--env GF_AUTH_GOOGLE_AUTH_URL=https://accounts.google.com/o/oauth2/auth \
	--env GF_AUTH_GOOGLE_TOKEN_URL=https://accounts.google.com/o/oauth2/token \
	--env GF_AUTH_GOOGLE_CLIENT_SECRET=${google_client_secret} \
	--env GF_AUTH_GOOGLE_CLIENT_ID=${google_client_id} \
	grafana/grafana:${grafana_docker_version}

unset GRAFANA_PW
# AWS Cloudwatch Logs - broken metrics section, interpolation issues, \ is not the answer to escape chars in terraform!

	# "metrics": {
	# 	"aggregation_dimensions": [
	# 		[
	# 			"InstanceId"
	# 		]
	# 	],
	# 	"append_dimensions": {
	# 		"AutoScalingGroupName": "\$\{aws:AutoScalingGroupName\}",
	# 		"ImageId": "\$\{aws:ImageId\}",
	# 		"InstanceId": "\$\{aws:InstanceId\}",
	# 		"InstanceType": "\$\{aws:InstanceType\}"
	# 	},
	# 	"metrics_collected": {
	# 		"cpu": {
	# 			"measurement": [
	# 				"cpu_usage_idle",
	# 				"cpu_usage_iowait",
	# 				"cpu_usage_user",
	# 				"cpu_usage_system"
	# 			],
	# 			"metrics_collection_interval": 60,
	# 			"resources": [
	# 				"*"
	# 			],
	# 			"totalcpu": false
	# 		},
	# 		"disk": {
	# 			"measurement": [
	# 				"used_percent",
	# 				"inodes_free"
	# 			],
	# 			"metrics_collection_interval": 60,
	# 			"resources": [
	# 				"*"
	# 			]
	# 		},
	# 		"diskio": {
	# 			"measurement": [
	# 				"io_time"
	# 			],
	# 			"metrics_collection_interval": 60,
	# 			"resources": [
	# 				"*"
	# 			]
	# 		},
	# 		"mem": {
	# 			"measurement": [
	# 				"mem_used_percent"
	# 			],
	# 			"metrics_collection_interval": 60
	# 		},
	# 		"statsd": {
	# 			"metrics_aggregation_interval": 60,
	# 			"metrics_collection_interval": 10,
	# 			"service_address": ":8125"
	# 		},
	# 		"swap": {
	# 			"measurement": [
	# 				"swap_used_percent"
	# 			],
	# 			"metrics_collection_interval": 60
	# 		}
	# 	}
	# }


reboot
