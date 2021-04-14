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
            "/bin/bash -c \"aws s3 mv ${var.file_path} ${var.dagster-container-home} --recursive\""
        ],
        "entryPoint": [
            "sh",
            "-c"
        ],
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
    subnets = [] //local.rds_ecs_subnet_ids
    //security_groups  = [aws_security_group.airflow.id]
    assign_public_ip = true //length(var.private_subnet_ids) == 0 ? true : false
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }
}
