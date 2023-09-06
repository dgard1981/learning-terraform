output "alb_public_dns_name" {
  description = "ALB public DNS name"
  value       = module.qa.lb_dns_name
}
