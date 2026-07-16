resource "aws_ecs_cluster" "api_cluster" {
  name = "${var.env_name}-api-cluster"

  setting {
    name  = "containerInsights"
    value = "enhanced"
  }
}
