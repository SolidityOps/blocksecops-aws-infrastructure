#!/bin/bash

# NAT Instance User Data Script
# Configures NAT functionality for cost-effective private subnet internet access

set -euo pipefail

# Update system
yum update -y

# Enable IP forwarding
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
sysctl -p

# Detect primary network interface (the one with default route)
PRIMARY_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

# Configure iptables for NAT using the primary interface
iptables -t nat -A POSTROUTING -o $PRIMARY_INTERFACE -s ${vpc_cidr} -j MASQUERADE
iptables -A FORWARD -i $PRIMARY_INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -o $PRIMARY_INTERFACE -j ACCEPT

# Save iptables rules
iptables-save > /etc/sysconfig/iptables

# Install iptables-services package for Amazon Linux 2
yum install -y iptables-services

# Enable and start iptables service
systemctl enable iptables
systemctl start iptables

# Disable source/destination check (already done in Terraform, but ensuring)
# This is handled by Terraform: source_dest_check = false

# Install CloudWatch agent for monitoring
yum install -y amazon-cloudwatch-agent

# Create CloudWatch config
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "metrics": {
        "namespace": "NAT/Instance",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            },
            "netstat": {
                "measurement": [
                    "tcp_established",
                    "tcp_time_wait"
                ],
                "metrics_collection_interval": 60
            },
            "swap": {
                "measurement": [
                    "swap_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/messages",
                        "log_group_name": "/aws/ec2/nat-instance",
                        "log_stream_name": "{instance_id}/messages"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Create a simple health check script
cat > /usr/local/bin/nat-health-check.sh << 'EOF'
#!/bin/bash

# Simple health check for NAT functionality
# Tests connectivity to external services

TEST_HOSTS=(
    "8.8.8.8"
    "1.1.1.1"
    "amazon.com"
)

HEALTH_STATUS=0

for host in "$${TEST_HOSTS[@]}"; do
    if ! ping -c 1 -W 5 "$host" >/dev/null 2>&1; then
        echo "Failed to reach $host" >&2
        HEALTH_STATUS=1
    fi
done

if [ $HEALTH_STATUS -eq 0 ]; then
    echo "NAT instance healthy"
else
    echo "NAT instance unhealthy" >&2
fi

exit $HEALTH_STATUS
EOF

chmod +x /usr/local/bin/nat-health-check.sh

# Add health check to cron (every 5 minutes)
echo "*/5 * * * * root /usr/local/bin/nat-health-check.sh >> /var/log/nat-health-check.log 2>&1" >> /etc/crontab

# Configure log rotation for health check logs
cat > /etc/logrotate.d/nat-health-check << 'EOF'
/var/log/nat-health-check.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOF

# Log successful completion for monitoring
echo "$(date): NAT instance user data script completed successfully" >> /var/log/nat-setup.log

echo "NAT instance configuration completed successfully"