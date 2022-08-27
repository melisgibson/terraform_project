# --- loadbalancer/outputs.tf ---
output "lb_tg_name" {
  value = aws_lb_target_group.web_lb_tg.name
}

output "lb_tg" {
  value = aws_lb_target_group.web_lb_tg.arn
}

output "alb_dns" {
  value = aws_lb.web_lb.dns_name
}