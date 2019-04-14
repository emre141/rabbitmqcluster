#variable "vpc_id" {}
variable "aws_region" {
  default = "region_please"
}
variable "ssh_key_name" {}
variable "aws_ami_id" {}
variable "environment" {}
variable "rabbitmqansiblebucket" {}
variable "dnsname_elb" {}
variable "volume_size" {}
variable "iops" {}
variable "mdsp_area" {}
variable "mdsp_environmet" {}
variable "mdsp_region_datacenter" {}
variable "mdsp_platform_services" {}
variable "mdsp_team" {}
variable "expiration_day" {
  default = "30"
}


variable "vpc_cidr" {}
variable "elb_security_group_cidr" {
  default = "0.0.0.0/0"
}
variable "isProd" {
  default = 0
}
variable "cidr_blocks" {
  type = "list"
  default = ["0.0.0.0/0"]
}
variable "asg_capacity" {
  default = 1
}

variable "instance_type" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "cert_external_name" {}
variable "cert_internal_name" {}
variable "rabbitmq_node_count" {}

variable "ref_arch_bucket" {
  description = "The bucket name of reference architecture, it starts with ''"
}
variable "ref_arch_path" {
  description = "The tfstate file where it is stored in reference architecture bucket"
}

#Consecutive period for cpu usage high
variable "cpuUsageHighEvaluation_periods" {
  default = 5
}

#Consecutive period for cpu usage low
variable "cpuUsageLowEvaluation_periods" {
  default = 6
}

#Number of period of metrics in "seconds" for cpu usage high
variable "cpuUsageHighPeriod" {
  default = 60
}

#Number of period of metrics in "seconds" for cpu usage low
variable "cpuUsageLowPeriod" {
  default = 300
}

#Threshold value for cpu usage high cloudwatch metric
variable "cpuUsageHighThreshold" {
  default = 80
}

#Threshold value for cpu usage low cloudwatch metric
variable "cpuUsageLowThreshold" {
  default = 10
}

variable "memoryUsageHighEvaluation_periods" {
  default = 5
}

variable "memoryUsageLowEvaluation_periods" {
  default = 6
}

#Number of period of metrics in "seconds" for cpu usage high
variable "memoryUsageHighPeriod" {
  default = 60
}

#Number of period of metrics in "seconds" for cpu usage low
variable "memoryUsageLowPeriod" {
  default = 300
}

#Threshold value for cpu usage high cloudwatch metric
variable "memoryUsageHighThreshold" {
  default = 80
}

#Threshold value for cpu usage low cloudwatch metric
variable "memoryUsageLowThreshold" {
  default = 10
}
#Consecutive period for disk usage high
variable "diskUsageHighEvaluation_periods" {
  default = 3
}


#Number of period of metrics in "seconds" for disk  usage high
variable "diskUsageHighPeriod" {
  default = 60
}

# Threshold value for Disk Space High Space Cloudwatch Metric
variable "diskUsageHighThreshold" {
  default = 60
}


#statistic Type. Other values are "Minimum" and "Maximum"
variable "statisticType" {
  default = "Average"
}

variable "metric_name" {
  default = "HealthCheck"
}

variable "alivenessThreshold" {
  default = 0
}

#Number of period of metrics in "seconds" for cpu usage low
variable "alivenessCheckPeriod" {
  default = 60
}

variable "alivenessCheckEvaluation_periods" {
  default = 3
}

variable "sns_topic_name" {
  default = ""
}
variable "cert_expire_topic_name" {}
variable "email_adresses" {
  type = "map"
  default = {
    "0" = {
      "email" = "someone@company.com"
    }

  }
}

variable "mdsp_backup" {
  default = "false"
}

variable "mdsp_contact" {
  default = ""
}
variable "mdsp_start_time" {
  default = "08:00"
}
variable "mdsp_stop_time" {
  default = "17:00"
}
variable "mdsp_team_timezone" {
  default = "UTC+3"
}
variable "mdsp_keepalive" {
  default = ""
}
variable "mdsp_pipeline_url" {
  default = ""
}
locals {
  common_tags = {
    mdsp-area                 = "${var.mdsp_area}"
    mdsp-environment          = "${var.mdsp_environmet}"
    mdsp-region-datacenter    = "${var.mdsp_region_datacenter}"
    mdsp-services             = "${var.mdsp_platform_services}"
    mdsp-team                 = "${var.mdsp_team}"
    mdsp-pipeline-url         = "${var.mdsp_pipeline_url}"
    mdsp-backup               = "${var.mdsp_backup}"
    mdsp-contact              = "${var.mdsp_contact}"
    mdsp-start-time           = "${var.mdsp_start_time}"
    mdsp-stop-time            = "${var.mdsp_stop_time}"
    mdsp-team-timezone        = "${var.mdsp_team_timezone}"
    mdsp-keepalive            = "${var.mdsp_keepalive}"
  }
}

