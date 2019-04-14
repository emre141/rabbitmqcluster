variable "service_name" {}
variable "timeout" {
  default = 60
}
variable "aliveness_endpoint" {}
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

variable "handler" {
  default = "healthcheck.lambda_handler"
}

variable "runtime" {
  default = "python3.6"
}
variable "private_subnet_list" {
  type = "list"
  default = []
}
variable "vpc_id" {}
variable "vpc_cidr" {}
variable "security_group_name" {}

resource "aws_security_group" "healthcheck_lambda_security_group" {
  name        = "${var.security_group_name}"
  description = "Allows ports 443"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 443
    to_port     = 443
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
  name        = "${var.service_name}-healthcheck_role"
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

resource "aws_iam_policy" "rabbitmq_healthcheck_lambda_access_policy" {
  name        = "${var.service_name}_healthcheck_lambda_access_policy"
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
          "cloudwatch:PutMetricData"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}



resource "aws_iam_role_policy_attachment" "rDBLambdaPolicyAttach" {
  role       = "${aws_iam_role.healthcheck_role.name}"
  policy_arn = "${aws_iam_policy.rabbitmq_healthcheck_lambda_access_policy.arn}"
}


resource "aws_lambda_function" "health_check_lambda" {
  function_name    = "${var.service_name}-HealthCheckMonitoring"
  role             = "${aws_iam_role.healthcheck_role.arn}"
  handler          = "${var.handler}"
  runtime          = "${var.runtime}"
  timeout          = "${var.timeout}"
  filename         = "${var.module_path}/platform/health-check/healthcheck.zip"
  source_code_hash = "${base64sha256(format("%s/platform/health-check/healthcheck.zip", var.module_path))}"
  memory_size      = "${var.memory_size}"
  vpc_config {
    security_group_ids = ["${aws_security_group.healthcheck_lambda_security_group.id}"]
    subnet_ids         = ["${var.private_subnet_list}"]
  }

  tags = "${merge(
    var.common_tags,
    map(
      "Name", "${var.environment}-AlivenessHC",
    )
  )}"
}

resource "aws_lambda_permission" "heap_usage_permission_for_cw" {
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.health_check_lambda.function_name}"
  principal = "events.amazonaws.com"
  statement_id = "${aws_cloudwatch_event_rule.healthcheck_event_rule.name}"
  source_arn = "${aws_cloudwatch_event_rule.healthcheck_event_rule.arn}"
}

resource "aws_cloudwatch_event_rule" "healthcheck_event_rule" {
  name        = "${var.service_name}-HealthCheckRuler"
  description = "${var.service_name}-HealthCheckRuler triggers lambda in every minute"
  schedule_expression = "cron(* * * * ? *)" #every minute
  tags = "${merge(
    var.common_tags,
    map(
      "Name", "${var.environment}-AlivenessHCRule",
    )
  )}"
}

resource "aws_cloudwatch_event_target" "event_target" {
  rule      = "${aws_cloudwatch_event_rule.healthcheck_event_rule.name}"
  arn       = "${aws_lambda_function.health_check_lambda.arn}"
  input = <<INPUT
  {
    "service_name": "${var.service_name}",
    "url_name": "${var.aliveness_endpoint}"
  }
INPUT
}

