resource "aws_appautoscaling_target" "authentication_api_target" {
  max_capacity       = var.auth_task_count_max
  min_capacity       = var.auth_task_count_min
  resource_id        = "service/${aws_ecs_cluster.api_cluster.name}/${aws_ecs_service.authentication_api_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "authentication_api_cpu_policy" {
  name               = "authentication-api-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.authentication_api_target.resource_id
  scalable_dimension = aws_appautoscaling_target.authentication_api_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.authentication_api_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 70.0

    # Scale in slowly to prevent "flapping"
    scale_in_cooldown = 300

    # Scale out quickly to handle the load
    scale_out_cooldown = 60
  }
}
