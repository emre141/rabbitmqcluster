data "aws_iam_policy_document" "policy_doc" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "template_file" "cloud-init" {
  template = "${file("${path.module}/cloud-init.yaml")}"

  vars {
    region            = "${var.aws_region}"
    message_timeout   = "${3 * 24 * 60 * 60 * 1000}"  # 3 days
    teamcluster       = "${var.environment}"
    asgname           =  "${format("%s", "rabbitmq-${var.environment}")}"
    aws_access_key    = "${var.aws_access_key}"
    aws_secret_key    = "${var.aws_secret_key}"
    bucket_name       = "${var.rabbitmqansiblebucket}"
  }
}

data "aws_iam_policy" "AmazonEC2RoleforSSM" {
   arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "ec2roleforssm-role-policy-attach" {
  role = "${aws_iam_role.role.name}"
  policy_arn = "${data.aws_iam_policy.AmazonEC2RoleforSSM.arn}"
}


resource "aws_iam_role" "role" {
  name               = "rabbitmq-${var.environment}"
  assume_role_policy = "${data.aws_iam_policy_document.policy_doc.json}"
}

resource "aws_iam_role_policy" "policy" {
  name   = "rabbitmq-${var.environment}"
  role   = "${aws_iam_role.role.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:*",
                "ec2:*",
                "s3:*",
                "cloudwatch:*",
                "ssm:*",
                "logs:*",
                "sns:*"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "profile" {
  name = "rabbitmq-${var.environment}"
  role = "${aws_iam_role.role.name}"
}


resource "aws_launch_configuration" "rabbitmq" {
  name_prefix          =  "rabbitmq-${var.environment}"
  image_id             =  "${var.aws_ami_id}"
  instance_type        =  "${var.instance_type}"
  key_name             =  "${var.ssh_key_name}"
  security_groups      =  ["${aws_security_group.rabbitmq-nodes.id}"]
  iam_instance_profile =  "${aws_iam_instance_profile.profile.id}"
  user_data            =  "${data.template_file.cloud-init.rendered}"
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "io1"
    volume_size = "${var.isProd == 0 ? var.volume_size: "150"}"
    delete_on_termination = true
    iops = "${var.isProd == 0 ? var.iops : "3000"}"
    encrypted = true
  }

  lifecycle {
    create_before_destroy = true
  }

}


resource "aws_autoscaling_group" "rabbitmq" {
  name                      = "rabbitmq-${var.environment}"
  max_size                  = "${var.rabbitmq_node_count}"
  min_size                  = "${var.rabbitmq_node_count}"
  desired_capacity          = "${var.rabbitmq_node_count}"
  health_check_grace_period = 1200
  health_check_type         = "EC2"
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.rabbitmq.name}"
  load_balancers            = ["${aws_elb.elb-external.name}","${aws_elb.elb-internal.name}"]
  vpc_zone_identifier       = ["${var.subnetlistprivate}"]
  depends_on                = ["aws_launch_configuration.rabbitmq"]

  lifecycle {
    create_before_destroy = true
  }

tags = [

    {  key = "Name"
       value = "rabbitmq-${var.environment}"
       propagate_at_launch = true
    },

    {
      key = "mdsp-area"
      value = "${var.mdsp_area}"
      propagate_at_launch = true
    },

    {
      key = "mdsp-environment"
      value = "${var.mdsp_environmet}"
      propagate_at_launch = true
    },

    {
      key = "mdsp-region-datacenter"
      value = "${var.mdsp_region_datacenter}"
      propagate_at_launch = true
    },

    {
      key = "mdsp-services"
      value = "${var.mdsp_platform_services}"
      propagate_at_launch = true
    },
    {
      key = "mdsp-team"
      value = "${var.mdsp_team}"
      propagate_at_launch = true
    },
    {
      key = "mdsp-pipeline-url"
      value = "${var.mdsp_pipeline_url}"
      propagate_at_launch = true
    },
    {
      key = "mdsp-keepalive"
      value = "${var.mdsp_keepalive}"
      propagate_at_launch = true
    },
    {
      key = "mdsp-start-time"
      value = "${var.mdsp_start_time}"
      propagate_at_launch = true
    },
    {
      key = "mdsp-stop-time"
      value = "${var.mdsp_stop_time}"
      propagate_at_launch = true
    },
    {
      key = "mdsp-team-timezone"
      value  = "${var.mdsp_team_timezone}"
      propagate_at_launch = true
    },
    {
      key = "mdsp-contact"
      value = "${var.mdsp_contact}"
      propagate_at_launch = true
    },
    {
      key = "mdsp-backup"
      value = "${var.mdsp_backup}"
      propagate_at_launch = true
    }

 ]
}

# Create a new ALB Target Group attachment

resource "aws_autoscaling_attachment" "asg_attachment_internal" {
  autoscaling_group_name = "${aws_autoscaling_group.rabbitmq.id}"
  elb   =  "${aws_elb.elb-internal.id}"

}

output "asg_instance_tag" {
  value = "${aws_autoscaling_group.rabbitmq.name}"
}