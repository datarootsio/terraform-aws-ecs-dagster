locals {
  dagster_variables = {
    PG_DB_CONN_STRING : "postgresql://${var.rds_username}:${var.rds_password}@${aws_db_instance.dagster[0].address}:${aws_db_instance.dagster[0].port}/${aws_db_instance.dagster[0].name}",
    DAGSTER_HOME : "${var.dagster-container-home}/",
    S3_BUCKET_NAME : local.dagster_container_home
  }
  dagster_container_home = "s3://${var.dagster_config_bucket}"

  ecs_rds_subnet                = length(var.private_subnet) == 0 ? var.public_subnet : var.private_subnet
  dagster_mounted_volume_name   = "dagster"
  sidecar_container_name        = "sidecar_container"
  dagit_container_name          = "dagit"
  dagster_daemon_container_name = "dagster_daemon"
}