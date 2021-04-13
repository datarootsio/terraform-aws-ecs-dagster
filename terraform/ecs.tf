
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