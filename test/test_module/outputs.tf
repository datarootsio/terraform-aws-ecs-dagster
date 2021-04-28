output "dagster_alb_dns" {
  description = "The DNS name of the ALB, with this you can access the dagster webserver"
  value       = module.aws_dagster.dagster_alb_dns
}

output "dagster_dns_record" {
  description = "The created DNS record (only if \"use_https\" = true)"
  value       = module.aws_dagster.dagster_dns_record
}

output "dagster_task_iam_role" {
  description = "The IAM role of the dagster task, use this to give dagster more permissions"
  value       = module.aws_dagster.dagster_task_iam_role
}

output "dagster_connection_sg" {
  description = "The security group with which you can connect other instance to dagster, for example EMR Livy"
  value       = module.aws_dagster.dagster_connection_sg
}