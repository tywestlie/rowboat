# Security group for the Solid Queue worker — no inbound, it accepts no
# connections. Egress open for RDS and outbound API calls via the NAT Gateway.
resource "aws_security_group" "ecs_worker" {
  name        = "${var.app_name}-ecs-worker-sg"
  description = "Solid Queue worker task, no inbound traffic accepted"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-ecs-worker-sg"
  }
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/ecs/${var.app_name}-worker"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "worker" {
  family                   = "${var.app_name}-worker-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name      = "${var.app_name}-worker"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/rowboat-web:latest"
      essential = true
      command   = ["./bin/jobs"]

      environment = [
        { name = "RAILS_ENV", value = "production" },
        { name = "DATABASE_HOST", value = aws_db_instance.main.address },
        { name = "DATABASE_NAME", value = var.db_name },
        { name = "DATABASE_USERNAME", value = var.db_username }
      ]

      secrets = [
        {
          name      = "ROWBOAT_DATABASE_PASSWORD"
          valueFrom = aws_secretsmanager_secret.db_password.arn
        },
        {
          name      = "RAILS_MASTER_KEY"
          valueFrom = aws_secretsmanager_secret.rails_master_key.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.worker.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.app_name}-worker-task"
  }
}

resource "aws_ecs_service" "worker" {
  name                   = "${var.app_name}-worker-service"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.worker.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_worker.id]
    assign_public_ip = false
  }

  tags = {
    Name = "${var.app_name}-worker-service"
  }
}
