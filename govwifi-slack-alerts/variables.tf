variable "london_critical_notifications_topic_arn" {
  type = string
}

variable "london_capacity_notifications_topic_arn" {
  type = string
}

variable "dublin_critical_notifications_topic_arn" {
  type = string
}

variable "dublin_capacity_notifications_topic_arn" {
  type = string
}

variable "route53_critical_notifications_topic_arn" {
  type = string
}

variable "smoketest_notifications_topic_arn" {
  type = string
}


variable "create_slack_alerts" {
  type = number
}
