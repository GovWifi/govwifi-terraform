#!/bin/bash

logger 'Govwifi Prometheus User Data Script - Starting'
echo "Govwifi Prometheus User Data Script - Starting"

export DEBIAN_FRONTEND=noninteractive

function run-until-success() {
  until $*
  do
    logger "Executing $* failed. Sleeping 5..."
    sleep 5
  done
}

## CREATE A VOLUME FOR PROMETHEUS INSTANCE DELETE AND ADD THIS TO TERRAFORM
logger 'Configuring prometheus EBS'
vol=""
while [ -z "$vol" ]; do
  # adapted from
  # https://medium.com/@moonape1226/mount-aws-ebs-on-ec2-automatically-with-cloud-init-e5e837e5438a
  # [Last accessed on 2020-04-02]
  vol=$(lsblk | grep -e disk | awk '{sub("G","",$4)} {if ($4+0 == ${data_volume_size}) print $1}')
  logger "still waiting for data volume ; sleeping 5"
  sleep 5
done
mkdir -p /srv/prometheus
logger "found volume /dev/$vol"
if [ -z "$(lsblk | grep "$vol" | awk '{print $7}')" ] ; then
  if [ -z "$(blkid /dev/$vol | grep ext4)" ] ; then
    logger "volume /dev/$vol is not formatted ; formatting"
    mkfs -F -t ext4 "/dev/$vol"
  else
    logger "volume /dev/$vol is already formatted"
  fi

  logger "volume /dev/$vol is not mounted ; mounting"
  mount "/dev/$vol" /srv/prometheus
  UUID=$(blkid /dev/$vol -s UUID -o value)
  if [ -z "$(grep $UUID /etc/fstab)" ] ; then
    logger "writing fstab entry"

    echo "UUID=$UUID /srv/prometheus ext4 defaults,nofail 0 2" >> /etc/fstab
  fi
fi

mkdir -p /srv/prometheus/metrics2
chown -R nobody /srv/prometheus


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
		"run_as_user": "root"
	},
	"logs": {
		"logs_collected": {
			"files": {
				"collect_list": [
					{
						"file_path": "/var/log/syslog",
						"log_group_class": "STANDARD",
						"log_group_name": "${prometheus-log-group}",
						"log_stream_name": "{instance_id}-syslog",
						"retention_in_days": 30
					},
					{
						"file_path": "/var/log/auth.log",
						"log_group_class": "STANDARD",
						"log_group_name": "${prometheus-log-group}",
						"log_stream_name": "{instance_id}-auth.log",
						"retention_in_days": 30
					},
					{
						"file_path": "/var/log/dmesg",
						"log_group_class": "STANDARD",
						"log_group_name": "${prometheus-log-group}",
						"log_stream_name": "{instance_id}-dmesg",
						"retention_in_days": 30
					},
					{
						"file_path": "/var/log/unattended-upgrades/unattended-upgrades.log",
						"log_group_class": "STANDARD",
						"log_group_name": "${prometheus-log-group}",
						"log_stream_name": "{instance_id}-unattended-upgrades.log",
						"retention_in_days": 30
					},
					{
						"file_path": "/var/log/cloud-init-output.log",
						"log_group_class": "STANDARD",
						"log_group_name": "${prometheus-log-group}",
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

# Remove trust-ad from /etc/resolv.conf to avoid Go bug
# This can probably be removed with Ubuntu/Prometheus is updated
sed -i s/\ trust-ad// /etc/resolv.conf

# Install Docker and Send Logs to cloudwatch
logger 'Installing and configuring docker'
mkdir -p /etc/systemd/system/docker.service.d
run-until-success apt-get install --yes docker.io
cat <<EOF > /etc/systemd/system/docker.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --log-driver awslogs --log-opt --log-opt awslogs-group=${prometheus-log-group} --dns 10.0.0.2
EOF

# Reload systemctl daemon to pick up new override files
systemctl stop docker
systemctl daemon-reload
systemctl enable --now docker

# Configure systemd to write prometheus data to the EBS volume on start up.
# This script will start prometheus automatically with the correct storage location,
# even if the instance is rebooted or the service crashes.
logger 'Configuring Prometheus start up script'
cat << EOF > /etc/systemd/system/prometheus-govwifi.service
 ${prometheus_startup}
EOF
# Reload systemctl daemon to pick up new override files
systemctl daemon-reload

# Install Prometheus
logger 'Installing prometheus'
run-until-success apt-get install --yes prometheus

## Configure Prometheus to write to EBS volume
chown -R prometheus:prometheus /srv/prometheus/metrics2

## Configure Prometheus scrape points
## This overwrites the existing prometheus configuration
logger 'Overwriting default Prometheus scraping configuation'
cat << EOF > /etc/prometheus/prometheus.yml
 ${prometheus_config}
EOF

## Install Prometheus Node exporter
logger 'Installing prometheus node exporter'
run-until-success apt-get install --yes prometheus-node-exporter
mkdir /etc/systemd/system/prometheus-node-exporter.service.d

# Create an environment file for prometheus node exporter
cat >  /etc/systemd/system/prometheus-node-exporter.service.d/prometheus-node-exporter.env <<EOF
ARGS="--collector.ntp --collector.diskstats.ignored-devices=^(ram|loop|fd|(h|s|v|xv)d[a-z]|nvme\\d+n\\d+p)\\d+$ --collector.filesystem.ignored-mount-points=^/(sys|proc|dev|run|var/lib/docker)($|/) --collector.netdev.ignored-devices=^lo$ --collector.textfile.directory=/var/lib/prometheus/node-exporter"
EOF

# Create an override file which will override prometheus node exporter service file
cat > /etc/systemd/system/prometheus-node-exporter.service.d/10-override-args.conf <<EOF
[Service]
EnvironmentFile=/etc/systemd/system/prometheus-node-exporter.service.d/prometheus-node-exporter.env
EOF
systemctl daemon-reload
systemctl enable prometheus-node-exporter
systemctl restart prometheus-node-exporter

logger 'Installing awscli'
run-until-success apt-get install --yes awscli

#Initialise a node_creation_time metric to enable the predict_linear function to handle new nodes
echo "node_creation_time $(date +%s)" > /var/lib/prometheus/node-exporter/node-creation-time.prom

cat <<EOF > /usr/bin/instance-reboot-required-metric.sh
#!/usr/bin/env bash

echo '# HELP node_reboot_required Node reboot is required for software updates.'
echo '# TYPE node_reboot_required gauge'
if [[ -f '/run/reboot-required' ]] ; then
  echo 'node_reboot_required 1'
else
  echo 'node_reboot_required 0'
fi
EOF

chmod +x /usr/bin/instance-reboot-required-metric.sh

run-until-success apt-get install --yes moreutils

crontab - <<EOF
$(crontab -l | grep -v 'no crontab')
*/5 * * * * /usr/bin/instance-reboot-required-metric.sh | sponge /var/lib/prometheus/node-exporter/reboot-required.prom
EOF

# Run prometheus with the EBS volume configuration
logger 'Stop Out of Box Prometheus'
service prometheus stop
systemctl disable prometheus
logger 'Enable Prometheus-Govwifi'
systemctl enable --now prometheus-govwifi
systemctl start prometheus-govwifi

reboot
