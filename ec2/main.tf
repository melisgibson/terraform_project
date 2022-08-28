# --- ec2/main.tf ---
data "aws_ami" "server_ami" {
  most_recent = true

  owners = ["137112412989"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.*.0-x86_64-gp2"]
  }
}

# Bastion host instance

resource "aws_launch_template" "bastion_host" {
  name_prefix = "bastion_host"
  instance_type = var.instance_type
  image_id          = data.aws_ami.server_ami.id
  vpc_security_group_ids = [var.bastion_sg]
  key_name = var.key_name

  tags = {
    Name = "bastion-host"
  }
}
  resource "aws_autoscaling_group" "bastion_host_asg" {
  name                = "bastion-asg"
  vpc_zone_identifier = var.public_subnets
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.bastion_host.id
    version = "$Latest"
  }
}

# Web server

resource "aws_launch_template" "web_server" {
  name_prefix   = "web-server"
  instance_type = var.instance_type
  image_id           = data.aws_ami.server_ami.id
  vpc_security_group_ids = [var.web_sg]
  key_name = var.key_name
  user_data = var.user_data

  tags = {
    Name = "web-server"
  }
}

data "aws_lb_target_group" "web_lb_tg" {
  name = var.lb_tg_name
}

resource "aws_autoscaling_group" "web_server_asg" {
  name                = "web-server-asg"
  vpc_zone_identifier = var.private_subnets
  min_size            = 2
  max_size            = 4
  desired_capacity    = 3

  target_group_arns = [data.aws_lb_target_group.web_lb_tg.arn]

  launch_template {
    id      = aws_launch_template.web_server.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_attachment" "asg_attach" {
  autoscaling_group_name = aws_autoscaling_group.web_server_asg.id
  lb_target_group_arn    = var.lb_tg
}
