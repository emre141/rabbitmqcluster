resource "aws_elb" "elb-external" {
  name = "rabbitmq-elb-${var.environment}-ext"

  access_logs {
    bucket = "${aws_s3_bucket.external_elb_s3_bucket.bucket}"
    enabled = true
  }

  listener {
    instance_port = 1883
    instance_protocol = "TCP"
    lb_port = 8883
    lb_protocol = "SSL"
    ssl_certificate_id = "${data.aws_acm_certificate.certificate_external.arn}"
  }

  health_check {
    interval            = 30
    unhealthy_threshold = 10
    healthy_threshold   = 2
    timeout             = 3
    target              = "TCP:1883"
  }

  subnets               = ["${var.subnetlistpublic}"]
  idle_timeout          = 3600
  internal              = false
  security_groups       = ["${aws_security_group.mqtt_ssl_external.id}"]

  tags = "${merge(
    var.common_tags,
    map(
      "Name", "${var.environment}-Ext-ELB",
    )
  )}"
}

resource "aws_elb" "elb-internal" {
  name                 = "rabbitmq-elb-${var.environment}-int"

  access_logs {
    bucket = "${aws_s3_bucket.internal_elb_s3_bucket.bucket}"
    enabled = true

  }

  listener {
    instance_port      = 15672
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${data.aws_acm_certificate.certificate_internal.arn}"
  }

  listener {
    instance_port      = 5672
    instance_protocol  = "TCP"
    lb_port            = 5672
    lb_protocol        = "TCP"
  }


  listener {
    instance_port = 1883
    instance_protocol = "TCP"
    lb_port = 8883
    lb_protocol = "SSL"
    ssl_certificate_id = "${data.aws_acm_certificate.certificate_internal.arn}"
  }

  health_check {
    interval            = 30
    unhealthy_threshold = 10
    healthy_threshold   = 2
    timeout             = 3
    target              = "TCP:1883"
  }

  subnets               = ["${var.subnetlistprivate}"]
  idle_timeout          = 3600
  internal              = true
  security_groups       = ["${aws_security_group.elb-internal-security-group.id}"]


  tags = "${merge(
    var.common_tags,
    map(
      "Name", "${var.environment}-Int-ELB",
    )
  )}"
}

data "aws_route53_zone" "mqtt_zone" {
  name =  "${var.isProd == 1 ? var.cert_external_name : var.ext_zone_name}"
  private_zone = false
}


resource "aws_route53_record" "rabbitmq_internal_elb" {
  name = "${var.dnsname_elb}"
  type = "A"
  zone_id = "${var.int_zone_id}"

  alias {
    evaluate_target_health = true
    name = "${aws_elb.elb-internal.dns_name}"
    zone_id = "${aws_elb.elb-internal.zone_id}"
  }

}

resource "aws_route53_record" "rabbitmq_external_elb" {
  name = "${var.isProd == 1 ? "" : var.dnsname_elb}"
  type = "A"
  zone_id = "${var.isProd == 1 ? data.aws_route53_zone.mqtt_zone.zone_id : var.ext_zone_id}"

  alias {
    evaluate_target_health = true
    name = "${aws_elb.elb-external.dns_name}"
    zone_id = "${aws_elb.elb-external.zone_id}"
  }

}


data "aws_acm_certificate" "certificate_internal" {
  domain = "${var.cert_internal_name}"
  statuses = ["ISSUED"]
}

data "aws_acm_certificate" "certificate_external" {
  domain = "${var.cert_external_name}"
  statuses = ["ISSUED"]
}

output "elb_external_arn" {
  value = "${aws_elb.elb-external.arn}"
}

output "elb_internal_arn" {
  value = "${aws_elb.elb-internal.arn}"
}

output "rabbitmq_internal_fqdn" {
  value = "${aws_route53_record.rabbitmq_internal_elb.*.fqdn}"
}

output "rabbitmq_external_fqdn" {
  value = "${aws_route53_record.rabbitmq_external_elb.*.fqdn}"
}

