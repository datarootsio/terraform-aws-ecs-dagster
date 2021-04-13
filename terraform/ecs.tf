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
            "/bin/bash -c \"aws s3 cp ${var.file_path} ${var.dagster-container-home} --recursive"
        ],
        "entryPoint": [
            "sh",
            "-c"
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
              "awslogs-group": "${aws_cloudwatch_log_group.dagster.name}",
              "awslogs-region": "eu-west-1",
              "awslogs-stream-prefix": "airflow"
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