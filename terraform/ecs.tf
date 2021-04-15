resource "aws_cloudwatch_log_group" "dagster" {
  name              = "dagster"
  retention_in_days = 1

  tags = var.tags
}

resource "aws_ecs_cluster" "dagster" {
  name               = "dagster-cluster"
  capacity_providers = ["FARGATE_SPOT", "FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
  }

  tags = var.tags
}

resource "aws_ecs_task_definition" "dagster" {
  family                   = "dagster-cluster"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.execution.arn

  volume {
    name = "dagster"
  }

  container_definitions = <<TASK_DEFINITION
      [
      {
        "image": "mikesir87/aws-cli",
        "name": "sidecar_container",
        "command": [
            "/bin/bash -c \"aws s3 cp s3://${var.dagster_config_bucket}/ ${var.dagster-container-home} --recursive\""
        ],
        "entryPoint": [
            "sh",
            "-c"
        ],
        "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
            "awslogs-group": "${aws_cloudwatch_log_group.dagster.name}",
            "awslogs-region": "${var.aws_region}",
            "awslogs-stream-prefix": "dagster"
          }
        },
        "essential": false,
        "mountPoints": [
          {
            "sourceVolume": "dagster",
            "containerPath": "${var.dagster-container-home}"
          }
        ]
      },
      {
        "image": "dagster/k8s-dagit-example",
        "name": "${var.resource_prefix}-dagster-webserver-${var.resource_suffix}",
        "dependsOn": [
            {
                "containerName": "sidecar_container",
                "condition": "SUCCESS"
            }
        ],
        "command": [
            "/bin/bash -c \"dagit -h 0.0.0.0 -p 8080 -w ${var.dagster-container-home}/${var.workspace_file}\""
        ],
        "entryPoint": [
            "sh",
            "-c"],
        "environment": [
          ${join(",\n", formatlist("{\"name\":\"%s\",\"value\":\"%s\"}", keys(local.dagster_variables), values(local.dagster_variables)))}
        ],
        "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
            "awslogs-group": "${aws_cloudwatch_log_group.dagster.name}",
            "awslogs-region": "${var.aws_region}",
            "awslogs-stream-prefix": "dagster"
          }
        },
        "essential": true,
        "mountPoints": [
          {
            "sourceVolume": "dagster",
            "containerPath": "${var.dagster-container-home}"
          }
        ],
        "portMappings": [
            {
                "containerPort": 8080,
                "hostPort": 8080
            }
        ]
      }
    ]
  TASK_DEFINITION

  tags = var.tags
}

resource "aws_ecs_service" "dagster" {
  depends_on = [aws_lb.dagster, aws_db_instance.dagster]

  name            = "dagster"
  cluster         = aws_ecs_cluster.dagster.id
  task_definition = aws_ecs_task_definition.dagster.id
  desired_count   = 1

  // health_check_grace_period_seconds = 120

  network_configuration {
    subnets          = ["subnet-08da686d46e99872d"] //local.rds_ecs_subnet_ids
    security_groups  = [aws_security_group.dagster.id]
    assign_public_ip = true //length(var.private_subnet_ids) == 0 ? true : false
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }

  load_balancer {
    container_name   = "${var.resource_prefix}-dagster-webserver-${var.resource_suffix}"
    container_port   = 8080
    target_group_arn = aws_lb_target_group.dagster.arn
  }

  tags = var.tags
}

resource "aws_lb_target_group" "dagster" {
  name        = "${var.resource_prefix}-dagster-${var.resource_suffix}"
  vpc_id      = var.vpc
  protocol    = "HTTP"
  port        = 8080
  target_type = "ip"

  health_check {
    port                = 8080
    protocol            = "HTTP"
    interval            = 30
    unhealthy_threshold = 5
    matcher             = "200-399"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}
