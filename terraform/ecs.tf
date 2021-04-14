resource "aws_cloudwatch_log_group" "dagster" {
  name              = "dagster"
  retention_in_days = 1
}

resource "aws_ecs_cluster" "dagster" {
  name               = "dagster-cluster"
  capacity_providers = ["FARGATE_SPOT", "FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
  }
}

resource "aws_ecs_task_definition" "dagster" {
  family                   = "dagster-cluster"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  network_mode             = "awsvpc"

  volume {
    name = "dagster"
  }

  container_definitions = <<TASK_DEFINITION
      [
      {
        "image": "mikesir87/aws-cli",
        "name": "sidecar_container",
        "command": [
            "/bin/bash -c \"aws s3 mv s3://dagster-first-buckett/hello_world.txt ${var.dagster-container-home}\""
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
        "essential": true,
        "mountPoints": [
          {
            "sourceVolume": "dagster",
            "containerPath": "${var.dagster-container-home}"
          }
        ]
      }
    ]
  TASK_DEFINITION
}

resource "aws_ecs_service" "dagster" {

  name            = "dagster"
  cluster         = aws_ecs_cluster.dagster.id
  task_definition = aws_ecs_task_definition.dagster.id
  desired_count   = 1

  // health_check_grace_period_seconds = 120

  network_configuration {
    subnets = ["subnet-08da686d46e99872d"] //local.rds_ecs_subnet_ids
    //security_groups  = [aws_security_group.airflow.id]
    assign_public_ip = true //length(var.private_subnet_ids) == 0 ? true : false
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }
}
