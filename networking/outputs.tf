# --- networking/outputs.tf ---

output "vpc_id" {
  value = aws_vpc.project_vpc.id
}

output "web_sg" {
  value = aws_security_group.web_sg.id
}

output "bastion_sg" {
  value = aws_security_group.bastion_sg.id
}

output "lb_sg" {
  value = aws_security_group.lb_sg.id
}

output "public_subnets" {
  value = aws_subnet.public_subnets.*.id
}

output "private_subnets" {
  value = aws_subnet.private_subnets.*.id
}