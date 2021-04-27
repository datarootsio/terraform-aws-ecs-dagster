output "dagster_alb_dns" {
  description = "The DNS name of the ALB, with this you can access the dagster webserver"
  value       = aws_lb.dagster.dns_name
}

output "dagster_dns_record" {
  description = "The created DNS record (only if \"use_https\" = true)"
  value       = local.dns_record
}

output "dagster_task_iam_role" {
  description = "The IAM role of the dagster task, use this to give dagster more permissions"
  value       = aws_iam_role.task
}

output "dagster_connection_sg" {
  description = "The security group with which you can connect other instance to dagster, for example EMR Livy"
  value       = aws_security_group.dagster
}