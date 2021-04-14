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

// ALB
resource "aws_lb" "dagster" {
  name               = "${var.resource_prefix}-dagster-${var.resource_suffix}"
  internal           = false
  load_balancer_type = "application"
  // security_groups    = [aws_security_group.alb.id, aws_security_group.airflow.id]
  subnets = var.public_subnet

  enable_deletion_protection = false

  tags = var.tags
}

resource "aws_lb_listener" "dagster" {
  load_balancer_arn = aws_lb.dagster.arn
  port              = "80"
  protocol          = "HTTP"
  certificate_arn   = ""

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dagster.arn
  }
}

resource "aws_lb_listener" "dagster_http_redirect" {
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