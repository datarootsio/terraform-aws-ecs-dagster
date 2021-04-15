locals {
  dagster_variables = {
    PG_DB_CONN_STRING : "postgresql://${var.rds_username}:${var.rds_password}@${aws_db_instance.dagster[0].address}:${aws_db_instance.dagster[0].port}/${aws_db_instance.dagster[0].name}",
    DAGSTER_HOME : var.dagster-container-home
  }
}