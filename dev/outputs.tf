output "alb_public_dns_name" {
  description = "ALB public DNS name"
  value       = module.dev.alb_public_dns_name
}
