data "aws_iam_policy_document" "ssm_lifecycle_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}


data "template_file" "ssmpolicy" {
  template = "${file((format("%s","${path.module}/policies/runpolicy.json")))}"

  vars {
    account_id  = "${data.aws_caller_identity.current.account_id}"
    resourcetag = "rabbitmq-${var.environment}"
  }
}

resource "aws_iam_policy" "ssm-run-command" {
  name = "rabbitmq-${var.environment}-policy"
  policy = "${data.template_file.ssmpolicy.rendered}"
}


resource "aws_iam_role_policy_attachment" "ssm-lifecycle-policy-attachment" {
  policy_arn = "${aws_iam_policy.ssm-run-command.arn}"
  role = "${aws_iam_role.role.name}"
}

resource "aws_iam_role_policy_attachment" "ec2roleforssm-role-policy-attachment2" {
  policy_arn = "${data.aws_iam_policy.AmazonEC2RoleforSSM.arn}"
  role = "${aws_iam_role.rabbitmq_ssm_run.name}"
}

resource "aws_iam_role" "rabbitmq_ssm_run" {
  assume_role_policy = "${data.aws_iam_policy_document.ssm_lifecycle_trust.json}"
  name = "rabbitmq-ssm-${var.environment}"
}


resource "aws_cloudwatch_event_rule" "ansible" {
  name = "rabbitmq-${var.environment}-ansible"
  description = "Run Playbook When any Action on Autoscaling Group"
  is_enabled = false
  tags = "${merge(
    var.common_tags,
    map(
      "Name", "${var.environment}-SSLExpireCheckRule",
    )
  )}"
  event_pattern = <<PATTERN
  {
    "source": [
      "aws.autoscaling"
    ],
    "detail-type": [
      "EC2 Instance Launch Successful",
      "EC2 Instance Terminate Successful",
      "EC2 Instance Launch Unsuccessful",
      "EC2 Instance Terminate Unsuccessful",
      "EC2 Instance-launch Lifecycle Action",
      "EC2 Instance-terminate Lifecycle Action"
    ],
    "detail": {
      "AutoScalingGroupName": [
        "rabbitmq-${var.environment}"
      ]
    }
  }

PATTERN
}

resource "aws_cloudwatch_event_target" "rabbitmqansibletarget" {
  arn = "arn:aws:ssm:${var.aws_region}::document/AWS-RunShellScript"
  target_id = "AutoScalingEvent"
  rule = "${aws_cloudwatch_event_rule.ansible.name}"
  input = "{\"commands\": [\"ansible-playbook /etc/ansible/roles/rabbitmq/tests/test.yml --connection=local --skip-tags 'reset' --extra-vars='teamcluster=${var.environment} \"]}"
  role_arn = "${aws_iam_role.role.arn}"

  run_command_targets {
    key = "tag:Name"
    values = ["rabbitmq-${var.environment}"]
  }
}


resource "aws_ssm_document" "runshellansible" {
  name          = "ssm-doc-ansible-${var.environment}"
  document_type = "Command"

  content = <<DOC
  {
   "schemaVersion":"2.2",
   "description":"Run Ansible Playbook",
   "mainSteps":[
      {
         "action":"aws:runShellScript",
         "name":"CopyFromS3",
         "precondition":{
            "StringEquals":[
               "platformType",
               "Linux"
            ]
         },
         "inputs":{
            "runCommand":[
               "export teamcluster='${var.environment}';aws s3 cp s3://${var.rabbitmqansiblebucket}/ansible /home/ec2-user/ansible.zip;unzip -o /home/ec2-user/ansible.zip -d /etc/ansible/roles"
            ]
         }
      },
      {
         "action":"aws:runShellScript",
         "name":"RunAnsbile",
         "precondition":{
            "StringEquals":[
               "platformType",
               "Linux"
            ]
         },
         "inputs":{
            "runCommand":[
               "export teamcluster='${var.environment}';ansible-playbook /etc/ansible/roles/rabbitmq/tests/test.yml  --skip-tags=reset --connection=local --extra-vars='teamcluster=${var.environment}'"
            ]
         }
      }
   ]
}

DOC
}

output "ssm_doc_name" {
  value = "${aws_ssm_document.runshellansible.name}"
}

output "s3_bucket_name" {
  value = "${var.rabbitmqansiblebucket}"
}

output "s3_key_prefix" {
  value = "ssmoutput-${var.environment}"
}