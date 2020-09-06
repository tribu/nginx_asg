data "aws_availability_zones" "all" {}

resource "aws_launch_configuration" "asg-launch-config-nginx" {
  image_id          = var.ami_id
  instance_type     = var.instance_type
  security_groups = [aws_security_group.nginx.id]
  #key_name = "test-dns"

  user_data = <<-EOF
              #!/bin/bash
              sudo apt install nginx -y &
             EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "nginx" {
  name = "terraform-nginx-sg"
  vpc_id = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elb-sg" {
  name = "terraform-nginx-elb-sg"
  vpc_id = var.vpc_id
  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Inbound HTTP from anywhere
  ingress {
    from_port   = var.elb_port
    to_port     = var.elb_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "asg-nginx" {
  launch_configuration = aws_launch_configuration.asg-launch-config-nginx.id
  availability_zones   = data.aws_availability_zones.all.names
  min_size = 2
  max_size = 5

  load_balancers    = [aws_elb.nginx.name]
  health_check_type = "ELB"

  tag {
    key                 = "Name"
    value               = "terraform-asg-nginx"
    propagate_at_launch = true
  }
}

resource "aws_elb" "nginx" {
  name               = "terraform-asg-nginx"
  security_groups    = [aws_security_group.elb-sg.id]
  availability_zones = data.aws_availability_zones.all.names

  health_check {
    target              = "HTTP:${var.server_port}/"
    interval            = 6
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  # Adding a listener for incoming HTTP requests.
  listener {
    lb_port           = var.elb_port
    lb_protocol       = "http"
    instance_port     = var.server_port
    instance_protocol = "http"
  }
}

