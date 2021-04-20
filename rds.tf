resource "aws_db_instance" "dagster" {
  count               = 1 // Can be less or more according to the need
  name                = "rds"
  allocated_storage   = 20
  storage_type        = "standard"
  engine              = "postgres"
  engine_version      = "11.10"
  instance_class      = var.rds_instance_class
  username            = var.rds_username
  password            = var.rds_password
  multi_az            = false
  availability_zone   = var.aws_availability_zone
  publicly_accessible = true
  deletion_protection = var.rds_deletion_protection
  skip_final_snapshot = true //var.rds_skip_final_snapshot
  //final_snapshot_identifier = "${var.resource_prefix}-airflow-${var.resource_suffix}-${local.timestamp_sanitized}"
  identifier             = "${var.resource_prefix}-dagster-${var.resource_suffix}"
  vpc_security_group_ids = [aws_security_group.dagster.id]
  db_subnet_group_name   = aws_db_subnet_group.dagster[0].name

  tags = var.tags
}

resource "aws_db_subnet_group" "dagster" {
  count = 1
  name  = "${var.resource_prefix}-dagster-${var.resource_suffix}"

  subnet_ids = local.ecs_rds_subnet

  tags = var.tags
}