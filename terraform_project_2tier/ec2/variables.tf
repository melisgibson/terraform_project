# --- ec2/variables.tf ---

variable "bastion_instance_count" {}
variable "instance_type" {}
variable "bastion_sg" {}
variable "private_subnets" { }
variable "public_subnets" {}
variable "key_name" {}
variable "lb_tg_name" {}
variable "lb_tg" {}
variable "web_sg" {}
variable "user_data" {}