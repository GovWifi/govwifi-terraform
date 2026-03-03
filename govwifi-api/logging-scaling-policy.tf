resource "aws_appautoscaling_target" "logging_ecs_target" {
  count              = var.logging_enabled
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.api_cluster.name}/${aws_ecs_service.logging_api_service[0].name}"
  max_capacity       = var.task_count_max
  min_capacity       = var.task_count_min
  scalable_dimension = "ecs:service:DesiredCount"
}

resource "aws_appautoscaling_policy" "ecs_policy_up_logging" {
  count              = var.logging_enabled
  name               = "ECS Scale Up Logging"
  service_namespace  = aws_appautoscaling_target.logging_ecs_target[0].service_namespace
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.logging_ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.logging_ecs_target[0].scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.logging_ecs_target]
}

resource "aws_appautoscaling_policy" "ecs_policy_down_logging" {
  count              = var.logging_enabled
  name               = "ECS Scale Down"
  service_namespace  = aws_appautoscaling_target.logging_ecs_target[0].service_namespace
  resource_id        = aws_appautoscaling_target.logging_ecs_target[0].resource_id
  policy_type        = "StepScaling"
  scalable_dimension = aws_appautoscaling_target.logging_ecs_target[0].scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.logging_ecs_target]
}

