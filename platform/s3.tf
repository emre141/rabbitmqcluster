resource "null_resource" "set_path" {
  triggers = {
    path_module = "${path.module}"
  }
}


data "archive_file" "archive-ansible" {
  source_dir = "${path.module}/ansible/"
  output_path = "${format("%s%s","rabbitmq-${var.environment}",".zip")}"
  type = "zip"
}


resource "aws_s3_bucket" "s3_bucket_for_ansible" {
  bucket      = "${var.rabbitmqansiblebucket}"
  acl         = "${var.acl}"
  force_destroy = true

  versioning {
    enabled = "${var.versioning}"
  }

  lifecycle_rule {
    enabled = "${var.lifecycle_rule}"

    expiration {
      days = "${var.expiration_days}"
    }

  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

    tags = "${merge(
    var.common_tags,
    map(
      "Name", "rabbitmq-${var.environment}",
    )
  )}"

}

resource "aws_s3_bucket_object" "ansibledirectory" {
  bucket = "${var.rabbitmqansiblebucket}"
  key =    "ansible"
  source = "${data.archive_file.archive-ansible.output_path}"
  etag = "${data.archive_file.archive-ansible.output_md5}"

  depends_on = ["aws_s3_bucket.s3_bucket_for_ansible"]
}

data "aws_caller_identity" "current" {}

data "template_file" "encrypted_bucket_policy_for_int_elb" {
  template = "${file((format("%s","${path.module}/policies/policy.json")))}"

  vars {
    bucket_name = "rabbitmq-${var.environment}-${data.aws_caller_identity.current.account_id}-int-elb-logs"
    account_id  = "${data.aws_caller_identity.current.account_id}"
  }
}

data "template_file" "encrypted_bucket_policy_for_ext_elb" {
  template = "${file((format("%s","${path.module}/policies/policy.json")))}"

  vars {
    bucket_name = "rabbitmq-${var.environment}-${data.aws_caller_identity.current.account_id}-ext-elb-logs"
    account_id  = "${data.aws_caller_identity.current.account_id}"
  }
}

resource "aws_s3_bucket" "external_elb_s3_bucket" {
  bucket = "rabbitmq-${var.environment}-${data.aws_caller_identity.current.account_id}-ext-elb-logs"
  acl    = "private"
  force_destroy = true

  versioning {

    enabled = "true"
  }

  lifecycle_rule {
    enabled = "true"

    expiration {
      days = "${var.expiration_day}"
  }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }


  policy = "${data.template_file.encrypted_bucket_policy_for_ext_elb.rendered}"

  tags = "${merge(
    var.common_tags,
    map(
      "Name", "${var.environment}-ext-elb-logs",
    )
  )}"
}

resource "aws_s3_bucket" "internal_elb_s3_bucket" {
  bucket = "rabbitmq-${var.environment}-${data.aws_caller_identity.current.account_id}-int-elb-logs"
  acl    = "private"
  force_destroy = true

  versioning {
    enabled = "true"
  }

  lifecycle_rule {

    enabled = "true"

    expiration {
      days = "${var.expiration_day}"
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }


  policy = "${data.template_file.encrypted_bucket_policy_for_int_elb.rendered}"

  tags = "${merge(
    var.common_tags,
    map(
      "Name", "${var.environment}-int-elb-logs",
    )
  )}"
}



