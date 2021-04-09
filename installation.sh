Steps to Configure AWS XRay Daemon and AWS CloudWatch Agent

mkdir /tmp/aws
wget -O /tmp/aws/amazon-cloudwatch-agent.rpm https://s3.amazonaws.com/amazoncloudwatch-agent/redhat/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U /tmp/aws/amazon-cloudwatch-agent.rpm

wget -O /tmp/aws/aws-xray-daemon.rpm https://s3.us-east-2.amazonaws.com/aws-xray-assets.us-east-2/xray-daemon/aws-xray-daemon-3.x.rpm
sudo rpm -U /tmp/aws/aws-xray-daemon.rpm

sudo systemctl stop xray
sudo systemctl stop amazon-cloudwatch-agent
sudo rm -rf /var/log/xray

sudo mkdir -p /var/log/amazon/{amazon-cloudwatch-agent,xray}
sudo chown -R scholar:scholar /var/log/amazon

sudo cp -f ./aws-xray/xray.service /etc/systemd/system/xray.service
sudo cp -f ./aws-xray/cfg.yaml /etc/amazon/xray/cfg.yaml
sudo cp -f ./aws-cw-agent/amazon-cloudwatch-agent.service /etc/systemd/system/amazon-cloudwatch-agent.service
sudo cp -f ./aws-cw-agent/common-config.toml /etc/amazon/amazon-cloudwatch-agent/common-config.toml
sudo cp -f ./aws-cw-agent/amazon-cloudwatch-agent.json /etc/amazon/amazon-cloudwatch-agent/amazon-cloudwatch-agent.json

sudo chown -R scholar:scholar /etc/amazon

sudo mkdir -p /srv/apps/.aws
sudo touch /srv/apps/.aws/{credentials,config}

sudo cp -f ./aws-cli/aws_config /srv/apps/.aws/config    
sudo cp -f ./aws-cli/aws_credentials /srv/apps/.aws/credentials

sudo chown -R scholar:scholar /srv/apps/.aws

sudo systemctl enable xray
sudo systemctl enable amazon-cloudwatch-agent
XRay Configuration Files

Service File: xray.service
[Unit]
Description=AWS X-Ray Daemon
After=network-online.target

[Service]
Type=simple
WorkingDirectory=/usr/bin/
User=scholar
Group=scholar
ExecStart=/usr/bin/xray -c /etc/amazon/xray/cfg.yaml
Restart=always
LogsDirectory=amazon/xray
LogsDirectoryMode=0755
ConfigurationDirectory=amazon/xray
ConfigurationDirectoryMode=0755

[Install]
WantedBy=network-online.target
Configuration file: cfg.yaml
# Maximum buffer size in MB (minimum 3). Choose 0 to use 1% of host memory.
TotalBufferSizeMB: 0
# Maximum number of concurrent calls to AWS X-Ray to upload segment documents.
Concurrency: 8
# Send segments to AWS X-Ray service in a specific region
Region: "us-east-2"
# Change the X-Ray service endpoint to which the daemon sends segment documents.
Endpoint: "https://xray.us-east-2.amazonaws.com"
Socket:
  # Change the address and port on which the daemon listens for UDP packets containing segment documents.
  UDPAddress: "127.0.0.1:2000"
  # Change the address and port on which the daemon listens for HTTP requests to proxy to AWS X-Ray.
  TCPAddress: "127.0.0.1:2000"
Logging:
  LogRotation: true
  # Change the log level, from most verbose to least: dev, debug, info, warn, error, prod (default).
  LogLevel: "prod"
  # Output logs to the specified file path.
  LogPath: "/var/log/amazon/xray/xray.log"
# Turn on local mode to skip EC2 instance metadata check.
LocalMode: true
# Amazon Resource Name (ARN) of the AWS resource running the daemon.
ResourceARN: ""
# Assume an IAM role to upload segments to a different account.
RoleARN: ""
# Disable TLS certificate verification.
NoVerifySSL: false
# Upload segments to AWS X-Ray through a proxy.
ProxyAddress: ""
# Daemon configuration file format version.
Version: 2
AWS CloudWatch Agent Configurations

common-config.toml
# This common-config is used to configure items used for both ssm and cloudwatch access

## Configuration for shared credential.
## Default credential strategy will be used if it is absent here:
## 	Instance role is used for EC2 case by default.
##	AmazonCloudWatchAgent profile is used for onPremise case by default.
[credentials]
    shared_credential_profile = "AmazonCloudWatchAgent"
    shared_credential_file = "/srv/apps/.aws/credentials"

## Configuration for proxy.
## System-wide environment-variable will be read if it is absent here.
## i.e. HTTP_PROXY/http_proxy; HTTPS_PROXY/https_proxy; NO_PROXY/no_proxy
## Note: system-wide environment-variable is not accessible when using ssm run-command.
## Absent in both here and environment-variable means no proxy will be used.
# [proxy]
#    http_proxy = "{http_url}"
#    https_proxy = "{https_url}"
#    no_proxy = "{domain}"

# [ssl]
#    ca_bundle_path = "{ca_bundle_file_path}"
amazon-cloudwatch-agent.service
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT

# Location: /etc/systemd/system/amazon-cloudwatch-agent.service
# systemctl enable amazon-cloudwatch-agent
# systemctl start amazon-cloudwatch-agent
# systemctl | grep amazon-cloudwatch-agent
# https://www.freedesktop.org/software/systemd/man/systemd.unit.html

[Unit]
Description=Amazon CloudWatch Agent
After=network.target

[Service]
Type=simple
ExecStart=/opt/aws/amazon-cloudwatch-agent/bin/start-amazon-cloudwatch-agent
KillMode=process
Restart=on-failure
RestartSec=60s

[Install]
WantedBy=multi-user.target
Example: amazon-cloudwatch-agent.json
{

      "agent": {

        "metrics_collection_interval": 60,

        "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log",

        "region": "us-east-2",

        "debug": false,

        "run_as_user": "scholar"

      },


 

      "metrics": {

        "namespace": "ScholarNamespace",

        "metrics_collected": {

          "cpu": {

            "resources": [

              "*"

            ],

            "measurement": [

              {"name": "cpu_usage_idle", "rename": "CPU_USAGE_IDLE", "unit": "Percent"},

              {"name": "cpu_usage_nice", "unit": "Percent"},

              "cpu_usage_guest"

            ],

            "totalcpu": false,

            "metrics_collection_interval": 10,

            "append_dimensions": {

              "customized_dimension_key_1": "customized_dimension_value_1",

              "customized_dimension_key_2": "customized_dimension_value_2"

            }

          },

          "disk": {

            "resources": [

              "/",

              "/tmp"

            ],

            "measurement": [

              {"name": "free", "rename": "DISK_FREE", "unit": "Gigabytes"},

              "total",

              "used"

            ],

             "ignore_file_system_types": [

              "sysfs", "devtmpfs"

            ],

            "metrics_collection_interval": 60,

            "append_dimensions": {

              "customized_dimension_key_3": "customized_dimension_value_3",

              "customized_dimension_key_4": "customized_dimension_value_4"

            }

          },

          "diskio": {

            "resources": [

              "*"

            ],

            "measurement": [

              "reads",

              "writes",

              "read_time",

              "write_time",

              "io_time"

            ],

            "metrics_collection_interval": 60

          },

          "swap": {

            "measurement": [

              "swap_used",

              "swap_free",

              "swap_used_percent"

            ]

          },

          "mem": {

            "measurement": [

              "mem_used",

              "mem_cached",

              "mem_total"

            ],

            "metrics_collection_interval": 1

          },

          "net": {

            "resources": [

              "eth0"

            ],

            "measurement": [

              "bytes_sent",

              "bytes_recv",

              "drop_in",

              "drop_out"

            ]

          },

          "netstat": {

            "measurement": [

              "tcp_established",

              "tcp_syn_sent",

              "tcp_close"

            ],

            "metrics_collection_interval": 60

          },

          "processes": {

            "measurement": [

              "running",

              "sleeping",

              "dead"

            ]

          }

        },

        "force_flush_interval" : 30

      },

      "logs": {

        "logs_collected": {

          "files": {

            "collect_list": [

              {

                "file_path": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log",

                "log_group_name": "/scholar/libschqwl1",

                "log_stream_name": "scholar_cloudwatch_agent",

                "timezone": "UTC"

              },

              {

               "file_path": "/srv/apps/curate_uc/log/production.log",

                "log_group_name": "/scholar/libschqwl1",

                "log_stream_name": "scholar_rails",

                "timezone": "UTC"

              },

              {

               "file_path": "/srv/apps/curate_uc/log/sidekiq.log",

                "log_group_name": "/scholar/libschqwl1",

                "log_stream_name": "scholar_sidekiq",

                "timezone": "UTC"

              }              

            ]

          }

        },

        "force_flush_interval" : 15

      }

    }
.aws/config
[default]
region = us-east-2
output = text

[AmazonCloudWatchAgent]
region = us-east-2
output = text
.aws/credentials
[default]
aws_access_key_id = 
aws_secret_access_key = 

[AmazonCloudWatchAgent]
aws_access_key_id = 
aws_secret_access_key = 
