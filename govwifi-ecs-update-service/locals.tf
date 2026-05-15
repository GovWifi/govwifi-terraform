locals {
  app = {
    admin = {
      service  = "admin-${var.env_name}"
      cluster  = "${var.env_name}-admin-cluster"
      task_def = "admin-task-${var.env_name}"
    }
    authentication-api = {
      service  = "authentication-api-service-${var.env_name}"
      cluster  = "${var.env_name}-api-cluster"
      task_def = "authentication-api-task-${var.env_name}"
    }
    frontend = {
      service  = "load-balanced-frontend"
      cluster  = "frontend-fargate"
      task_def = "frontend-fargate"
    }
    logging-api = {
      service  = "logging-api-service-${var.env_name}"
      cluster  = "${var.env_name}-api-cluster"
      task_def = "logging-api-task-${var.env_name}"
    }
    user-signup-api = {
      service  = "user-signup-api-service-${var.env_name}"
      cluster  = "${var.env_name}-api-cluster"
      task_def = "user-signup-api-task-${var.env_name}"
    }
    metrics-api = {
      service  = "metrics-api-service-${var.env_name}"
      cluster  = "${var.env_name}-metrics-cluster"
      task_def = "metrics-api-task-${var.env_name}"
    }
    tableau-bridge = {
      service  = "tableau-bridge-service-${var.env_name}"
      cluster  = "${var.env_name}-metrics-cluster"
      task_def = "tableau-bridge-task-${var.env_name}"
    }
  }
}
