# Alarm when EventBridge fails to invoke the metrics logging tasks.
#
# AWS/Events FailedInvocations increments when EventBridge cannot deliver to the ECS target
# (e.g. task failed to start, ECS API returned an error). This complements the Metrics API
# log metric filter in govwifi-metrics/alarms.tf, which catches application-level failures
# where the task ran but no data reached the API.

resource "aws_cloudwatch_metric_alarm" "daily_metrics_logging_failed_invocations" {
  count = var.event_rule_count

  alarm_name          = "${var.env_name}-daily-metrics-logging-failed-invocations"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedInvocations"
  namespace           = "AWS/Events"
  period              = "86400"
  statistic           = "Sum"
  threshold           = "1"
  datapoints_to_alarm = "1"
  treat_missing_data  = "notBreaching"

  dimensions = {
    RuleName = aws_cloudwatch_event_rule.daily_metrics_logging_event[count.index].name
  }

  alarm_description = "EventBridge failed to invoke the daily metrics logging ECS task. The task may have failed to start. Check EventBridge rule '${var.env_name}-daily-metrics-logging' and the ECS cluster task history."

  alarm_actions = [var.capacity_notifications_arn]
  ok_actions    = [var.capacity_notifications_arn]
}
