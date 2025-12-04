output "alb_dns" {
  value       = module.asg.alb_dns
  description = "ALB DNS name"
}

output "asg_name" {
  value       = module.asg.asg_name
  description = "Auto Scaling Group name"
}