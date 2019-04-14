ref_arch_bucket="bucket"
ref_arch_path="key_path"

ssh_key_name = "rabbitmq"
instance_type = "c5.large"
#please give ip address to allow external access rabbitmq
cidr_blocks = ["0.0.0.0/0"]

aws_region =  "<region>"


cert_external_name = "cert_internal"
cert_internal_name = "cert_external"
# please give vpc_cidr block
vpc_cidr = "0.0.0.0/0"


volume_size = 20
iops = 100
rabbitmq_node_count = 2
aws_ami_id = "ami_id"
environment = "environment"
dnsname_elb= "dns_name"
isProd = 0
rabbitmqansiblebucket = "bucket"
sns_topic_name = "RabbitMQ-SNS-Topic"
cert_expire_topic_name = "RabbitMQ-CertExpire-SNS"


##### Cost Tagging ##########
mdsp_area = ""
mdsp_environmet = ""
mdsp_region_datacenter = ""
mdsp_platform_services= ""
mdsp_team = ""
mdsp_keepalive = ""
mdsp_start_time = ""
mdsp_stop_time = ""