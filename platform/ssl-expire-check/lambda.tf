variable "service_name" {}
variable "timeout" {
  default = 10
}
variable "domainname" {}
variable "module_path" {}
variable "memory_size" {
  default = 128
}
variable "common_tags" {
  type = "map"
}
variable "mdsp_environmet" {}
variable "mdsp_region_datacenter"{}
variable "mdsp_platform_services" {}
variable "mdsp_team" {}


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
variable "environment" {}
variable "cert_expire_topic_name" {}
variable "aws_region" {}

variable "handler" {
  default = "sslexpirecheck.lambda_handler"
}

variable "runtime" {
  default = "python2.7"
}
variable "private_subnet_list" {
  type = "list"
  default = []
}

variable "email_adresses" {
  type = "map"
}

variable "vpc_id" {}
variable "vpc_cidr" {}
variable "security_group_name" {}

resource "aws_security_group" "sslexpirecheck_lambda_security_group" {
  name        = "${var.security_group_name}"
  description = "Allows ports 8883"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 8883
    to_port     = 8883
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.security_group_name}"
  }
}

resource "aws_iam_role" "healthcheck_role" {
  name        = "${var.service_name}-sslexpirecheck-Role"
  path        = "/"
  description = "Allows Lambda Function to call AWS services on your behalf."

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "rabbitmq_sslexpirecheck_lambda_access_policy" {
  name        = "${var.service_name}_sslexpirecheck_lambda_access_policy"
  description = "Allow lambda to access SSM and CloudWatch"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
          "ec2:Describe*",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ssm:GetParameters",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "cloudwatch:PutMetricData",
          "sns:Publish"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}


## Creates Simple Notification Service (SNS) topic for SSL Expire
resource "aws_sns_topic" "ssl_expire_alarm_topic" {
  display_name = "${var.cert_expire_topic_name}"
  name         = "${var.cert_expire_topic_name}"
  provisioner "local-exec" {
    command = "aws sns subscribe --topic-arn ${self.arn} --protocol email --notification-endpoint ${lookup(var.email_adresses[count.index],"email")} --region ${var.aws_region}"
  }
}


resource "aws_iam_role_policy_attachment" "rDBLambdaPolicyAttach" {
  role       = "${aws_iam_role.healthcheck_role.name}"
  policy_arn = "${aws_iam_policy.rabbitmq_sslexpirecheck_lambda_access_policy.arn}"
}


resource "aws_lambda_function" "sslexpire_check_lambda" {
  function_name    = "${var.service_name}-SSLExpire_CheckMonitoring"
  role             = "${aws_iam_role.healthcheck_role.arn}"
  handler          = "${var.handler}"
  runtime          = "${var.runtime}"
  timeout          = "${var.timeout}"
  filename         = "${var.module_path}/platform/ssl-expire-check/sslexpirecheck.zip"
  source_code_hash = "${base64sha256(format("%s/platform/ssl-expire-check/sslexpirecheck.zip", var.module_path))}"
  memory_size      = "${var.memory_size}"
  vpc_config {
    security_group_ids = ["${aws_security_group.sslexpirecheck_lambda_security_group.id}"]
    subnet_ids         = ["${var.private_subnet_list}"]
  }

  tags = "${merge(
    var.common_tags,
    map(
      "Name", "${var.environment}-SSLExpireCheck",
    )
  )}"
}

resource "aws_lambda_permission" "heap_usage_permission_for_cw" {
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.sslexpire_check_lambda.function_name}"
  principal = "events.amazonaws.com"
  statement_id = "${aws_cloudwatch_event_rule.healthcheck_event_rule.name}"
  source_arn = "${aws_cloudwatch_event_rule.healthcheck_event_rule.arn}"
}

resource "aws_cloudwatch_event_rule" "healthcheck_event_rule" {
  name        = "${var.service_name}-SSLExpireCheckRuler"
  description = "${var.service_name}-SSLExpireCheckRuler triggers lambda in every minute"
  schedule_expression = "cron(0 12 * * ? *)" #every day
  tags = "${merge(
    var.common_tags,
    map(
      "Name", "${var.environment}-SSLExpireCheckRule",
    )
  )}"
}

resource "aws_cloudwatch_event_target" "event_target" {
  rule      = "${aws_cloudwatch_event_rule.healthcheck_event_rule.name}"
  arn       = "${aws_lambda_function.sslexpire_check_lambda.arn}"
  input = <<INPUT
  {
    "url_name": "${var.domainname}",
    "sns_topic_arn": "${aws_sns_topic.ssl_expire_alarm_topic.arn}",
    "service_name": "${var.service_name}"
  }
INPUT
}
