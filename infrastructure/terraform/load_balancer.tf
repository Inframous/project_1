resource "aws_lb" "sql_proj1_loadbalancer" {
  name               = "sql-proj1-loadblanacer"
  internal           = false
  load_balancer_type = "application"
  
  subnets            = [ aws_subnet.sql_proj1_public_subnet.id, aws_subnet.sql_proj1_public_subnet2.id]
  
  security_groups    = [ aws_security_group.sql_proj1_sg.id ]
  
  enable_deletion_protection = false
}

resource "aws_lb_listener" "sql_proj1_listener" {
  load_balancer_arn = aws_lb.sql_proj1_loadbalancer.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    
    target_group_arn = aws_lb_target_group.sql_proj1_target_group.arn
  }
}

resource "aws_lb_target_group" "sql_proj1_target_group" {
  name     = "sql-proj1-tg" 
  port     = 80
  protocol = "HTTP"
  
  target_type = "instance"
  vpc_id = aws_vpc.sql_proj1_vpc.id
  
  health_check {
    path                = "/health"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "sql_proj1_lb_tg_attachments" {
  for_each = {
    "instance-1" = aws_instance.dev_node["11"].id
    "instance-2" = aws_instance.dev_node["12"].id
  }

  target_group_arn = aws_lb_target_group.sql_proj1_target_group.arn
  target_id        = each.value
  port             = 80
}
