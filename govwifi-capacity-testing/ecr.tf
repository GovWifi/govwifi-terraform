resource "aws_ecr_repository" "capacity_testing" {
  name                 = "govwifi-capacity-testing"
  image_tag_mutability = "MUTABLE"
  force_delete         = false

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "govwifi-capacity-testing"
  }
}

resource "aws_ecr_repository_policy" "capacity_testing" {
  repository = aws_ecr_repository.capacity_testing.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCodeBuildPush"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = [
          "ecr:*"
        ]
      },
      {
        Sid    = "AllowECSTaskExecutionPull"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
      }
    ]
  })
}
