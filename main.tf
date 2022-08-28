# --- root/main.tf --- 

module "networking" {
  source           = "./networking"
  vpc_cidr         = local.vpc_cidr
  private_sn_count = 3
  public_sn_count  = 3
  private_cidrs    = [for i in range(1, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  public_cidrs     = [for i in range(2, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  max_subnets      = 3
  access_ip        = var.access_ip
}


module "loadbalancing" {
  source            = "./loadbalancing"
  lb_sg             = module.networking.lb_sg
  public_subnets    = module.networking.public_subnets
  tg_port           = 80
  tg_protocol       = "HTTP"
  vpc_id            = module.networking.vpc_id
  web_asg           = module.ec2.web_asg
  listener_port     = 80
  listener_protocol = "HTTP"
}

module "ec2" {
  source                 = "./ec2"
  bastion_sg             = module.networking.bastion_sg
  web_sg                 = module.networking.web_sg
  public_subnets         = module.networking.public_subnets
  private_subnets        = module.networking.private_subnets
  bastion_instance_count = 1
  instance_type          = "t2.micro"
  key_name               = "MyKey"
  user_data              = filebase64("./userdata.tpl")
  lb_tg_name             = module.loadbalancing.lb_tg_name
  lb_tg                  = module.loadbalancing.lb_tg
}