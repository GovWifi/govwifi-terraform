resource "aws_appautoscaling_target" "auth_ecs_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.api_cluster.name}/${aws_ecs_service.authentication_api_service.name}"
  max_capacity       = 20
  min_capacity       = 2
  scalable_dimension = "ecs:service:DesiredCount"
}

resource "aws_appautoscaling_policy" "ecs_policy_up" {
  name               = "ECS Scale Up"
  service_namespace  = "ecs"
  policy_type        = "StepScaling"
  resource_id        = "service/${aws_ecs_cluster.api_cluster.name}/${aws_ecs_service.authentication_api_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.auth_ecs_target]
}

resource "aws_appautoscaling_policy" "ecs_policy_down" {
  name               = "ECS Scale Down"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.api_cluster.name}/${aws_ecs_service.authentication_api_service.name}"
  policy_type        = "StepScaling"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.auth_ecs_target]
}

