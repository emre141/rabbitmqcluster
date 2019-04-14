provider "aws" {
  region     = "${var.aws_region}"
}

provider "archive" {
  version = "~> 1.0"
}

terraform {
  backend "s3" {}
}

resource "null_resource" "set_path" {
  triggers = {
    path_module = "${path.module}"
  }
}

module "rabbitmqcluster" {
  source                                    = "platform"
  environment                               = "${var.environment}"
  vpcid                                     = "${data.terraform_remote_state.reference_arch.vpc_id}"
  vpc_cidr                                  = "${var.vpc_cidr}"
  elb_security_group_cidr                   = "${var.elb_security_group_cidr}"
  module_path                               = "${null_resource.set_path.triggers.path_module}"
  subnetlistpublic                          = ["${data.terraform_remote_state.reference_arch.public-subnets}"]
  subnetlistprivate                         = ["${data.terraform_remote_state.reference_arch.priv-subnets}"]
  cert_external_name                        = "${var.cert_external_name}"
  cert_internal_name                        = "${var.cert_internal_name}"
  aws_region                                = "${var.aws_region}"
  isProd                                    = "${var.isProd}"
  siemens_sgs-http-https                    = ["${data.terraform_remote_state.reference_arch.siemens-securitygroups-http-https}"]
  ext_zone_id                               = "${data.terraform_remote_state.reference_arch.ext_zone_id}"
  int_zone_id                               = "${data.terraform_remote_state.reference_arch.int_zone_id}"
  ext_zone_name                             = "${data.terraform_remote_state.reference_arch.ext_zone_name}"
  int_zone_name                             = "${data.terraform_remote_state.reference_arch.int_zone_name}"
  dnsname_elb                               = "${var.dnsname_elb}"
  common_tags                               = "${local.common_tags}"
  mdsp_area                                 = "${var.mdsp_area}"
  mdsp_environmet                           = "${var.mdsp_environmet}"
  mdsp_region_datacenter                    = "${var.mdsp_region_datacenter}"
  mdsp_platform_services                    = "${var.mdsp_platform_services}"
  mdsp_team                                 = "${var.mdsp_team}"
  mdsp_pipeline_url                         = "${var.mdsp_pipeline_url}"
  mdsp_backup                               = "${var.mdsp_backup}"
  mdsp_contact                              = "${var.mdsp_contact}"
  mdsp_start_time                           = "${var.mdsp_start_time}"
  mdsp_stop_time                            = "${var.mdsp_stop_time}"
  mdsp_team_timezone                        = "${var.mdsp_team_timezone}"
  mdsp_keepalive                            = "${var.mdsp_keepalive}"
  rabbitmqansiblebucket                     = "${var.rabbitmqansiblebucket}"
  aws_access_key                            = "${var.aws_access_key}"
  aws_secret_key                            = "${var.aws_secret_key}"
  aws_ami_id                                = "${var.aws_ami_id}"
  instance_type                             = "${var.instance_type}"
  ssh_key_name                              = "${var.ssh_key_name}"
  rabbitmq_node_count                       = "${var.rabbitmq_node_count}"
  volume_size                               = "${var.volume_size}"
  iops                                      = "${var.iops}"
  cidr_blocks                               = "${var.cidr_blocks}"
  cpuUsageHighEvaluation_periods            = "${var.cpuUsageHighEvaluation_periods}"
  cpuUsageLowEvaluation_periods             = "${var.cpuUsageLowEvaluation_periods}"
  cpuUsageHighPeriod                        = "${var.cpuUsageHighPeriod}"
  cpuUsageLowPeriod                         = "${var.cpuUsageLowPeriod}"
  cpuUsageHighThreshold                     = "${var.cpuUsageHighThreshold}"
  cpuUsageLowThreshold                      = "${var.cpuUsageLowThreshold}"

  memoryUsageHighEvaluation_periods         =  "${var.memoryUsageHighEvaluation_periods}"
  memoryUsageLowEvaluation_periods          =  "${var.memoryUsageLowEvaluation_periods}"
  memoryUsageHighPeriod                     =  "${var.memoryUsageHighPeriod}"
  memoryUsageLowPeriod                      =  "${var.memoryUsageLowPeriod}"
  memoryUsageHighThreshold                  =  "${var.memoryUsageHighThreshold}"
  memoryUsageLowThreshold                   =  "${var.memoryUsageLowThreshold}"

  diskUsageHighEvaluation_periods           =  "${var.diskUsageHighEvaluation_periods}"
  diskUsageHighPeriod                       =  "${var.diskUsageHighPeriod}"
  diskUsageHighThreshold                    =  "${var.diskUsageHighThreshold}"


  statisticType                             =  "${var.statisticType}"
  metric_name                               =  "${var.metric_name}"
  alivenessThreshold                        =  "${var.alivenessThreshold}"
  alivenessCheckPeriod                      =  "${var.alivenessCheckPeriod}"
  alivenessCheckEvaluation_periods          =  "${var.alivenessCheckEvaluation_periods}"
  sns_topic_name                            =  "${var.sns_topic_name}"
  email_adresses                            =  "${var.email_adresses}"
  expiration_day                            =  "${var.expiration_day}"

}

module "lambda" {
  source                                 = "platform/health-check"
  aliveness_endpoint                     = "${module.rabbitmqcluster.rabbitmq_internal_fqdn[0]}"
  service_name                           = "${format("%s","RabbitMQ-${var.environment}")}"
  module_path                            = "${null_resource.set_path.triggers.path_module}"
  private_subnet_list                    = ["${data.terraform_remote_state.reference_arch.priv-subnets}"]
  vpc_id                                 = "${data.terraform_remote_state.reference_arch.vpc_id}"
  vpc_cidr                               = "${var.vpc_cidr}"
  security_group_name                    = "${format("%s","RabbitMQHealthCheckLambda-${var.environment}-sg")}"
  common_tags                            = "${local.common_tags}"
  mdsp_area                              = "${var.mdsp_area}"
  mdsp_environmet                        = "${var.mdsp_environmet}"
  mdsp_region_datacenter                 = "${var.mdsp_region_datacenter}"
  mdsp_platform_services                 = "${var.mdsp_platform_services}"
  mdsp_team                              = "${var.mdsp_team}"
  mdsp_pipeline_url                      = "${var.mdsp_pipeline_url}"
  mdsp_backup                            = "${var.mdsp_backup}"
  mdsp_contact                           = "${var.mdsp_contact}"
  mdsp_start_time                        = "${var.mdsp_start_time}"
  mdsp_stop_time                         = "${var.mdsp_stop_time}"
  mdsp_team_timezone                     = "${var.mdsp_team_timezone}"
  mdsp_keepalive                         = "${var.mdsp_keepalive}"
  environment                            = "${var.environment}"
}


module "sslexpirelambda" {
  source                                 = "platform/ssl-expire-check"
  domainname                             ="${module.rabbitmqcluster.rabbitmq_external_fqdn[0]}"
  service_name                           = "${format("%s","RabbitMQ-${var.environment}")}"
  module_path                            = "${null_resource.set_path.triggers.path_module}"
  private_subnet_list                    = ["${data.terraform_remote_state.reference_arch.priv-subnets}"]
  vpc_id                                 = "${data.terraform_remote_state.reference_arch.vpc_id}"
  vpc_cidr                               = "${var.vpc_cidr}"
  security_group_name                    = "${format("%s","RabbitMQSSLExpireCheckLambda-${var.environment}-sg")}"
  common_tags                            = "${local.common_tags}"
  mdsp_area                              = "${var.mdsp_area}"
  mdsp_environmet                        = "${var.mdsp_environmet}"
  mdsp_region_datacenter                 = "${var.mdsp_region_datacenter}"
  mdsp_platform_services                 = "${var.mdsp_platform_services}"
  mdsp_team                              = "${var.mdsp_team}"
  mdsp_pipeline_url                      = "${var.mdsp_pipeline_url}"
  mdsp_backup                            = "${var.mdsp_backup}"
  mdsp_contact                           = "${var.mdsp_contact}"
  mdsp_start_time                        = "${var.mdsp_start_time}"
  mdsp_stop_time                         = "${var.mdsp_stop_time}"
  mdsp_team_timezone                     = "${var.mdsp_team_timezone}"
  mdsp_keepalive                         = "${var.mdsp_keepalive}"
  environment                            = "${var.environment}"
  cert_expire_topic_name                 = "${var.cert_expire_topic_name}"
  email_adresses                         =  "${var.email_adresses}"
  aws_region                             = "${var.aws_region}"
}


data "terraform_remote_state" "reference_arch" {
  backend = "s3"

  config {
    bucket = "${var.ref_arch_bucket}"
    key    = "${var.ref_arch_path}"
    region = "${var.aws_region}"
  }
}


output "elb_external_arn" {
  value = "${module.rabbitmqcluster.elb_external_arn}"
}

output "elb_internal_arn" {
  value = "${module.rabbitmqcluster.elb_internal_arn}"
}




