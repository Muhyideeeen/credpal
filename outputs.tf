###############################################################
# outputs.tf
###############################################################

output "app_url" {
  description = "Your application URL"
  value       = "https://${var.domain_name}"
}

output "alb_dns_name" {
  description = "ALB DNS name — add this as a CNAME in GoDaddy for www"
  value       = aws_lb.main.dns_name
}

output "certificate_status" {
  description = "ACM certificate status — must be ISSUED before app is reachable over HTTPS"
  value       = aws_acm_certificate.main.status
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.app.name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for container logs"
  value       = aws_cloudwatch_log_group.app.name
}

output "godaddy_instructions" {
  description = "What to add in GoDaddy DNS after applying"
  value       = <<-EOT

  ── GoDaddy DNS Setup ──────────────────────────────────────────

  1. SSL Validation (go to AWS Console → Certificate Manager → your cert):
     Add the CNAME record shown under "Domains" in GoDaddy DNS.

  2. Point your domain at the app:
     Type : CNAME
     Name : www
     Value: ${aws_lb.main.dns_name}

  3. For root domain (@), use GoDaddy Domain Forwarding:
     Forward to: https://www.${var.domain_name}  (Permanent 301)

  ──────────────────────────────────────────────────────────────
  EOT
}
