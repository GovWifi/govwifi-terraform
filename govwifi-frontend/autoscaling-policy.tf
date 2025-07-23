resource "aws_appautoscaling_target" "ecs_radius_frontend_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.frontend_fargate.name}/${aws_ecs_service.load_balanced_frontend_service.name}"
  max_capacity       = var.radius_task_count_max
  min_capacity       = var.radius_task_count_min
  scalable_dimension = "ecs:service:DesiredCount"
}

resource "aws_appautoscaling_policy" "ecs_service_radius_frontend_load_scale_up_policy" {
  name = "${aws_ecs_service.load_balanced_frontend_service.name}-open-sessions-step-scaling-UP"
  service_namespace = "ecs"
  resource_id = aws_appautoscaling_target.ecs_radius_frontend_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_radius_frontend_target.scalable_dimension
  policy_type = "StepScaling"

  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity" # Add/remove a fixed number of tasks
    cooldown = 300 # Cooldown period in seconds
    metric_aggregation_type = "Sum" # Sum of metric values over the period

    step_adjustment {
      metric_interval_lower_bound = 0 # If metric value is > 0
      scaling_adjustment = 1 # Add 1 task
    }
    # You can add more step adjustments for more aggressive scaling
  }
  depends_on = [aws_appautoscaling_target.ecs_radius_frontend_target]
}

resource "aws_appautoscaling_policy" "ecs_service_radius_frontend_load_scale_down_policy" {
  name = "${aws_ecs_service.load_balanced_frontend_service.name}-open-sessions-step-scaling-DOWN"
  service_namespace = "ecs"
  resource_id = aws_appautoscaling_target.ecs_radius_frontend_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_radius_frontend_target.scalable_dimension
  policy_type = "StepScaling"

  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity" # Add/remove a fixed number of tasks
    cooldown = 3600 # Cooldown period in seconds, leave grace period for traffic to calm down before reducing tasks
    metric_aggregation_type = "Sum" # Sum of metric values over the period

    step_adjustment {
      metric_interval_lower_bound = 0 # If metric value is > 0
      scaling_adjustment = -1 # Remove 1 task
    }
    # You can add more step adjustments for more aggressive scaling
  }
  depends_on = [aws_appautoscaling_target.ecs_radius_frontend_target]
}

/*
resource "aws_appautoscaling_policy" "ecs_policy_up_radiusentication_api" {
  name               = "ECS Scale Up"
  service_namespace  = "ecs"
  policy_type        = "StepScaling"
  resource_id        = "service/${aws_ecs_cluster.api_cluster.name}/${aws_ecs_service.load_balanced_frontend_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.radius_ecs_target_radiusentication_api]
}


resource "aws_appautoscaling_policy" "ecs_policy_down_radiusentication_api" {
  name               = "ECS Scale Down"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.api_cluster.name}/${aws_ecs_service.radiusentication_api_service.name}"
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

  depends_on = [aws_appautoscaling_target.radius_ecs_target_radiusentication_api]
}
*/