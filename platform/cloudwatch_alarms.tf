#### CPU Utilization Alarm Definition Begin ####
resource "aws_cloudwatch_metric_alarm" "cpu_utilization_high" {
  alarm_name          = "RabbitMQ-CPUUtilizationHigh-${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${var.cpuUsageHighEvaluation_periods}"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "${var.cpuUsageHighPeriod}"
  statistic           = "${var.statisticType}"
  threshold           = "${var.cpuUsageHighThreshold}"

  dimensions {
    AutoScalingGroupName  = "rabbitmq-${var.environment}"
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions = ["${aws_sns_topic.rabbitmq_alarms_sns.arn}"]
  insufficient_data_actions = ["${aws_sns_topic.rabbitmq_alarms_sns.arn}"]
  ok_actions = ["${aws_sns_topic.rabbitmq_alarms_sns.arn}"]

}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_low" {
  alarm_name          = "RabbitMQ-CPUUtilizationLow-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "${var.cpuUsageLowEvaluation_periods}"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "${var.cpuUsageLowPeriod}"
  statistic           = "${var.statisticType}"
  threshold           = "${var.cpuUsageLowThreshold}"

  dimensions {
    AutoScalingGroupName  = "rabbitmq-${var.environment}"
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions = ["${aws_sns_topic.rabbitmq_alarms_sns.arn}"]
  insufficient_data_actions = ["${aws_sns_topic.rabbitmq_alarms_sns.arn}"]
  ok_actions = ["${aws_sns_topic.rabbitmq_alarms_sns.arn}"]


}
#### CPU Utilization Alarm Definition End ####


#### Memory Utilization Alarm Definition Begin ####
resource "aws_cloudwatch_metric_alarm" "memory_utilization_high" {
  alarm_name          = "RabbitMQ-MemoryUtilizationHigh-${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${var.memoryUsageHighEvaluation_periods}"
  metric_name         = "MemoryUtilization"
  namespace           = "System/Linux"
  period              = "${var.memoryUsageHighPeriod}"
  statistic           = "${var.statisticType}"
  threshold           = "${var.memoryUsageHighThreshold}"

  dimensions {
    AutoScalingGroupName  = "rabbitmq-${var.environment}"
  }

  alarm_description = "This metric monitors ec2 memory utilization"
  alarm_actions = ["${aws_sns_topic.rabbitmq_alarms_sns.arn}"]
  insufficient_data_actions = ["${aws_sns_topic.rabbitmq_alarms_sns.arn}"]
  ok_actions = ["${aws_sns_topic.rabbitmq_alarms_sns.arn}"]


}

resource "aws_cloudwatch_metric_alarm" "memory_utilization_low" {
  alarm_name          = "RabbitMQ-MemoryUtilizationLow-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "${var.memoryUsageLowEvaluation_periods}"
  metric_name         = "MemoryUtilization"
  namespace           = "System/Linux"
  period              = "${var.memoryUsageLowPeriod}"
  statistic           = "${var.statisticType}"
  threshold           = "${var.memoryUsageLowThreshold}"

  dimensions {
    AutoScalingGroupName  = "rabbitmq-${var.environment}"
  }

  alarm_description = "This metric monitors ec2 memory utilization"
  alarm_actions = ["${aws_sns_topic.rabbitmq_alarms_sns.arn}"]
  insufficient_data_actions = ["${aws_sns_topic.rabbitmq_alarms_sns.arn}"]
  ok_actions = ["${aws_sns_topic.rabbitmq_alarms_sns.arn}"]

}

#### Memory Utilization Alarm Definition End ####

#### Disk Utilization Alarm Definition Begin ####

resource "aws_cloudwatch_metric_alarm" "rabbitpath_disk_utilization_high" {
  alarm_name          = "RabbitMQ-DiskUtilizationHighRabbitPath-${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${var.diskUsageHighEvaluation_periods}"
  metric_name         = "DiskSpaceUtilization"
  namespace           = "System/Linux"
  period              = "${var.diskUsageHighPeriod}"
  statistic           = "${var.statisticType}"
  threshold           = "${var.diskUsageHighThreshold}"

  dimensions {
    AutoScalingGroupName  = "rabbitmq-${var.environment}"
    MountPath             = "/data/rabbitmq"
    Filesystem            = "/dev/mapper/rabbitmqvg-rabbitmqlv"
  }

  alarm_description = "This metric monitors rabbitmq path utilization"
  alarm_actions = ["${aws_sns_topic.rabbitmq_alarms_sns.arn}"]
  insufficient_data_actions = ["${aws_sns_topic.rabbitmq_alarms_sns.arn}"]
  ok_actions = ["${aws_sns_topic.rabbitmq_alarms_sns.arn}"]

}

resource "aws_cloudwatch_metric_alarm" "rootpath_disk_utilization_high" {
  alarm_name          = "RabbitMQ-DiskUtilizationHighRootPath-${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${var.diskUsageHighEvaluation_periods}"
  metric_name         = "DiskSpaceUtilization"
  namespace           = "System/Linux"
  period              = "${var.diskUsageHighPeriod}"
  statistic           = "${var.statisticType}"
  threshold           = "${var.diskUsageHighThreshold}"


  dimensions {
    AutoScalingGroupName  = "rabbitmq-${var.environment}"
    MountPath             = "/"
    #Filesystem            = "/dev/nvme0n1p1"
  }

  alarm_description = "This metric monitors ec2 root mount path  utilization"
  alarm_actions = ["${aws_sns_topic.rabbitmq_alarms_sns.arn}"]
  insufficient_data_actions = ["${aws_sns_topic.rabbitmq_alarms_sns.arn}"]
  ok_actions = ["${aws_sns_topic.rabbitmq_alarms_sns.arn}"]

}

#### Disk Utilization Alarm Definition End ####

## Creates CloudWatch monitor
resource "aws_cloudwatch_metric_alarm" "service_availability_alarm" {
  actions_enabled     = true
  alarm_name          = "RabbitMQ-ServiceAvailability-${var.environment}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "${var.alivenessCheckEvaluation_periods}"
  metric_name        = "${var.metric_name}"
  namespace          = "RabbitMQ Health Check Metrics"
  period             = "${var.alivenessCheckPeriod}"
  statistic          = "${var.statisticType}"
  threshold          = "${var.alivenessThreshold}"

  dimensions  {
    "ServiceName" = "RabbitMQ-${var.environment}"
  }


  alarm_description   = "This metric monitors service availability"
  alarm_actions = ["${aws_sns_topic.rabbitmq_alarms_sns.arn}"]
  insufficient_data_actions = ["${aws_sns_topic.rabbitmq_alarms_sns.arn}"]
  ok_actions = ["${aws_sns_topic.rabbitmq_alarms_sns.arn}"]
}

## Creates Simple Notification Service (SNS) topic
resource "aws_sns_topic" "rabbitmq_alarms_sns" {
  display_name = "${var.sns_topic_name}"
  name         = "${var.sns_topic_name}"
}

resource "null_resource" "rabbitmq_alarm_subscription" {
  count = "${length(var.email_adresses)}"

  provisioner "local-exec" {
    command = "aws sns subscribe --topic-arn ${aws_sns_topic.rabbitmq_alarms_sns.arn} --protocol email --notification-endpoint ${lookup(var.email_adresses[count.index],"email")} --region ${var.aws_region}"
  }
  depends_on = ["aws_sns_topic.rabbitmq_alarms_sns"]
}