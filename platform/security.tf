resource "aws_security_group" "mqtt_ssl_external" {
  name        = "rabbitmq-mqtts-anytoany-sg-ext-${var.environment}"
  description = "Allows port mqtt for elb"
  vpc_id      = "${var.vpcid}"

  ingress {
    from_port   = 8883
    to_port     = 8883
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_blocks}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(
    var.common_tags,
    map(
      "Name", "rabbitmq-mqtts-anytoany-sg-ext-${var.environment}",
    )
  )}"

}

resource "aws_security_group" "rabbitmq-nodes" {
  name        = "rabbitmq-nodes-${var.environment}"
  vpc_id      = "${var.vpcid}"
  description = "Security Group for the RabbitMQ nodes"


  ingress {
    protocol        = "tcp"
    from_port       = 0
    to_port         = 65535
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = "${merge(
    var.common_tags,
    map(
      "Name", "rabbitmq-nodes-${var.environment}",
    )
  )}"

}

resource "aws_security_group" "elb-internal-security-group" {
  name        = "rabbitmq-elb-${var.environment}-int"
  description = "Security Group for the RabbitMQ  ELB Internal"
  vpc_id      = "${var.vpcid}"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["${var.elb_security_group_cidr}"]
  }


  tags = "${merge(
    var.common_tags,
    map(
      "Name", "rabbitmq-elb-${var.environment}-int",
    )
  )}"

}


