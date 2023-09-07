output "lb_dns_name" {
  description = "ALB public DNS name"
  value       = module.blog_alb.lb_dns_name
}
