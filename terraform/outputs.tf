output "alb_dns_name" {
  description = "Public URL to access the app"
  value       = "http://${aws_lb.main.dns_name}"
}

output "rds_endpoint" {
  description = "RDS connection endpoint"
  value       = aws_db_instance.main.address
  sensitive   = false
}

output "ecr_repository_url" {
  description = "ECR repo URL for pushing new images"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/rowboat-web"
}