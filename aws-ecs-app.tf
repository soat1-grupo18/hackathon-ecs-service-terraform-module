resource "aws_ecs_task_definition" "app" {
  family                   = var.app_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name              = var.app_name
      image             = var.app_docker_image
      cpu               = 256
      memoryReservation = 512
      memory            = 512
      essential         = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "logs"
        }
      }
      portMappings = [
        {
          name          = "http"
          containerPort = var.app_docker_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "PORT", value = tostring(var.app_docker_port) }
      ]
      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl --fail http://localhost:${var.app_docker_port}${var.app_health_check_path}"
        ]
        interval    = 10
        timeout     = 5
        retries     = 10
        startPeriod = 5
      }
    }
  ])
}

resource "aws_ecs_service" "app" {
  cluster         = data.aws_ecs_cluster.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  name            = var.app_name
  task_definition = aws_ecs_task_definition.app.arn

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    subnets = data.aws_subnets.fiap_private.ids
    # assign_public_ip = true is required to pull images from docker hub when it on a public subnet
    # docs: https://docs.aws.amazon.com/AmazonECS/latest/userguide/fargate-task-networking.html
    assign_public_ip = false
    security_groups  = [aws_security_group.app.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.lb_ingress_app_blue.arn
    container_name   = var.app_name
    container_port   = var.app_docker_port
  }

  lifecycle {
    ignore_changes = [
      desired_count,
    ]
  }
}

resource "aws_ecr_repository" "app" {
  name = var.app_name
  # IMMUTABLE is a better option because it making rollback and troubleshooting simpler! 
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}
