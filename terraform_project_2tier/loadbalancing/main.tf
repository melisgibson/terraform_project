# --- loadbalancer/main.tf ---

resource "aws_lb" "web_lb" {
  name            = "web-lb"
  subnets         = var.public_subnets
  security_groups = [var.lb_sg]
  idle_timeout    = 400

    depends_on = [
      var.web_asg
  ]
}

resource "aws_lb_target_group" "web_lb_tg" {
  name     = "web-lb-tg-${substr(uuid(), 0, 3)}"
  port     = var.tg_port
  protocol = var.tg_protocol
  vpc_id   = var.vpc_id
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }
}

resource "aws_lb_listener" "web_lb_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = var.listener_port
  protocol          = var.listener_protocol
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_lb_tg.arn
  }
}