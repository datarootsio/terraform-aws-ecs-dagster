// SG only meant for the alb to connect to the outside world
resource "aws_security_group" "alb" {
  vpc_id      = var.vpc
  name        = "${var.resource_prefix}-alb-${var.resource_suffix}"
  description = "Security group for the alb attached to the dagster ecs task"

  egress {
    description = "Allow all traffic out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_security_group_rule" "alb_outside_http" {
  for_each          = local.inbound_ports
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  protocol          = "TCP"
  from_port         = each.value
  to_port           = each.value
  cidr_blocks       = var.ip_allow_list
}


resource "aws_security_group" "dagster" {
  vpc_id      = var.vpc
  name        = "${var.resource_prefix}-dagster-${var.resource_suffix}"
  description = "Security group to connect to the dagster instance"

  egress {
    description = "Allow all traffic out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags

}

resource "aws_security_group_rule" "dagster_connection" {
  security_group_id        = aws_security_group.dagster.id
  type                     = "ingress"
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  source_security_group_id = aws_security_group.dagster.id
}

// ALB
resource "aws_lb" "dagster" {
  name               = "${var.resource_prefix}-dagster-${var.resource_suffix}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id, aws_security_group.dagster.id]
  subnets            = var.public_subnet

  enable_deletion_protection = false

  tags = var.tags
}

resource "aws_lb_listener" "dagster" {
  load_balancer_arn = aws_lb.dagster.arn
  port              = var.use_https ? "443" : "80"
  protocol          = var.use_https ? "HTTPS" : "HTTP"
  certificate_arn   = var.use_https ? local.certificate_arn : ""

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dagster.arn
  }
}

resource "aws_lb_listener" "dagster_http_redirect" {
  // Change this once we have https
  count             = 0
  load_balancer_arn = aws_lb.dagster.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}