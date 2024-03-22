data "aws_lb" "lb_ingress" {
  name = "fiap-lb-ingress"
}

data "aws_lb_listener" "lb_ingress_http" {
  load_balancer_arn = data.aws_lb.lb_ingress.arn
  port              = 80
}

resource "aws_lb_listener_rule" "lb_ingress_http_app" {
  listener_arn = data.aws_lb_listener.lb_ingress_http.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_ingress_app.arn
  }

  condition {
    host_header {
      values = [format("%s.ogn.one", var.app_name)]
    }
  }
}

resource "aws_lb_target_group" "lb_ingress_app" {
  name        = format("%s-tg", var.app_name)
  port        = var.app_docker_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.fiap.id

  health_check {
    enabled = true

    healthy_threshold   = 2
    interval            = 10
    matcher             = "200-299"
    path                = var.app_health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 5
  }

  deregistration_delay = 60
}
