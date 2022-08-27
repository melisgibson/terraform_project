# --- loadbalancer/variables.tf ---
variable "lb_sg" {}
variable "public_subnets" {}
variable "web_asg" {}
variable "tg_port" {}
variable "tg_protocol" {}
variable "vpc_id" {}
variable "listener_port" {}
variable "listener_protocol" {}