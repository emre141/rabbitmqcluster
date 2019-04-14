variable "environment" {}
variable "vpcid" {}
variable "vpc_cidr" {}
variable "elb_security_group_cidr" {}
variable "aws_region" {}
variable "module_path" {}
variable "cert_external_name" {}
variable "cert_internal_name" {}
variable "isProd" {}
variable "siemens_sgs-http-https" {
  type = "list"
}
variable "cidr_blocks" {
  type = "list"
}
variable "volume_size" {}
variable "iops" {}
variable "ext_zone_id" {}
variable "int_zone_id" {}
variable "ext_zone_name" {}
variable "int_zone_name" {}
variable "dnsname_elb" {}
variable "rabbitmqansiblebucket" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_ami_id" {}
variable "ssh_key_name" {}
variable "rabbitmq_node_count" {}
variable "instance_type" {}
variable "expiration_day" {}
variable "subnetlistpublic" {
  type = "list"
}
variable "subnetlistprivate" {
  type = "list"
}

#S3 bucket variables
variable "acl" {
  default = "private"
}
variable "versioning" {
  default = false
}
variable "lifecycle_rule" {
  default = true
}
variable "expiration_days" {
  default = 30
}
variable "use_s3_bucket_policy" {
  default = false
}


### CPU Utilization Alarm Threshold Variables ###
variable "cpuUsageHighEvaluation_periods" {}
variable "cpuUsageLowEvaluation_periods" {}
variable "cpuUsageHighPeriod" {}
variable "cpuUsageLowPeriod" {}
variable "cpuUsageHighThreshold" {}
variable "cpuUsageLowThreshold" {}


### Memory Utilization Alarm Threshold Variables ###
variable "memoryUsageHighEvaluation_periods" {}
variable "memoryUsageLowEvaluation_periods" {}
variable "memoryUsageHighPeriod" {}
variable "memoryUsageLowPeriod" {}
variable "memoryUsageHighThreshold" {}
variable "memoryUsageLowThreshold" {}

### Disk Utilization Alarm Threshold Variables ###
variable "diskUsageHighEvaluation_periods" {}
variable "diskUsageHighPeriod" {}
variable "diskUsageHighThreshold" {}


variable "statisticType" {}
variable "metric_name" {}
variable "alivenessThreshold" {}
variable "alivenessCheckPeriod" {}
variable "alivenessCheckEvaluation_periods" {}
variable "sns_topic_name" {}

variable "email_adresses" {
  type = "map"
}
variable "mdsp_environmet" {}
variable "mdsp_region_datacenter"{}
variable "mdsp_platform_services" {}
variable "mdsp_team" {}
variable "common_tags" {
  type = "map"
}

variable "mdsp_area" {
  default = ""
}
variable "mdsp_pipeline_url" {
  default = ""
}
variable "mdsp_backup" {
  default = ""
}
variable "mdsp_contact" {
  default = ""
}
variable "mdsp_start_time" {
  default = ""
}
variable "mdsp_stop_time" {
  default = ""
}
variable "mdsp_team_timezone" {
  default = ""
}
variable "mdsp_keepalive" {
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