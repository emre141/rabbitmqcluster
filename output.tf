output "asg_instance_tag" {
  value = "${module.rabbitmqcluster.asg_instance_tag}"
}

output "ssm_doc_name" {
  value = "${module.rabbitmqcluster.ssm_doc_name}"
}

output "s3_bucket_name" {
  value = "${module.rabbitmqcluster.s3_bucket_name}"
}

output "s3_key_prefix" {
  value = "${module.rabbitmqcluster.s3_key_prefix}"
}
output "rabbitmq_internal_endpoint" {
  value = "${module.rabbitmqcluster.rabbitmq_internal_fqdn}"
}

output "rabbitmq_external_endpoint" {
  value = "${module.rabbitmqcluster.rabbitmq_external_fqdn}"
}

