resource "aws_appautoscaling_target" "ecs_radius_frontend_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.frontend_fargate.name}/${aws_ecs_service.load_balanced_frontend_service.name}"
  max_capacity       = var.radius_task_count_max
  min_capacity       = var.radius_task_count_min
  scalable_dimension = "ecs:service:DesiredCount"
}

resource "aws_appautoscaling_policy" "ecs_service_radius_frontend_load_scale_up_policy" {
  name               = "${aws_ecs_service.load_balanced_frontend_service.name}-open-sessions-step-scaling-UP"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.ecs_radius_frontend_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_radius_frontend_target.scalable_dimension
  policy_type        = "StepScaling"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity" # Add/remove a fixed number of tasks
    cooldown                = 60                 # Cooldown period in seconds
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0 # If metric value is > 0
      scaling_adjustment          = 1 # Add 1 task
    }
  }
  depends_on = [aws_appautoscaling_target.ecs_radius_frontend_target]
}

/* no scale down policy, this is deliberate, see dev docs for reasons */

