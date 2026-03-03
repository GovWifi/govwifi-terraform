resource "aws_appautoscaling_target" "user_signup_api_target" {
  count              = var.user_signup_enabled
  max_capacity       = var.task_count_max
  min_capacity       = var.task_count_min
  resource_id        = "service/${aws_ecs_cluster.api_cluster.name}/${aws_ecs_service.user_signup_api_service[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "user_signup_api_cpu_policy" {
  count              = var.user_signup_enabled
  name               = "user-signup-api-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.user_signup_api_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.user_signup_api_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.user_signup_api_target[0].service_namespace

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