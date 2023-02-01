provider "aws" {
    region = "eu-west-2"
    access_key = "<access_key>"
    secret_key = "<secret_key>"
}



resource "aws_vpc" "trial-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "subnet-1" {
    vpc_id   = aws_vpc.trial-vpc.id
    availability_zone = "eu-west-2a"
    map_public_ip_on_launch = true
    cidr_block = "10.0.1.0/24"

    tags = {
        Name = "prod-subnet"
    }
}

resource "aws_subnet" "subnet-2" {
    vpc_id   = aws_vpc.trial-vpc.id
    availability_zone = "eu-west-2b"
    map_public_ip_on_launch = true
    cidr_block = "10.0.2.0/24"

    tags = {
        Name = "dev-subnet"
    }
}

resource "aws_subnet" "subnet-3" {
    vpc_id   = aws_vpc.trial-vpc.id
    availability_zone = "eu-west-2c"
    map_public_ip_on_launch = true
    cidr_block = "10.0.3.0/24"

    tags = {
        Name = "ola-subnet"
    }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.trial-vpc.id

}


resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.trial-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }


  tags = {
    Name = "ola"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet-2.id
  route_table_id = aws_route_table.prod-route-table.id
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.subnet-3.id
  route_table_id = aws_route_table.prod-route-table.id
}

# Create a security group for the load balancer

resource "aws_security_group" "terraform-load_balancer_sg" {
  name        = "load-balancer-sg"
  description = "Security group for the load balancer"
  vpc_id      = aws_vpc.trial-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.trial-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

    ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

    ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_WEB"
  }
}


# Create a instance1

resource "aws_instance" "terraform-instance1" {
  ami               = "ami-0d09654d0a20d3ae2"
  instance_type     = "t2.micro"
  availability_zone = "eu-west-2a"
  key_name          = "Barakat"
  subnet_id         = aws_subnet.subnet-1.id
  security_groups   = [aws_security_group.allow_web.id]
  tags = {
    Name = "instance1-terra"
  }
  user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update -y
                sudo apt-get install nginx -y
                sudo systemctl start nginx.service
                sudo systemctl enable nginx.service
                host=$(hostname)
                ip=$(ifconfig | grep 'inet ' | grep -v '127.0.0.1' | cut -c 7-17)
                sudo chown -R $USER:$USER /var/www
                echo 'Host name / IP address for this server is '$host'' > /var/www/html/index.nginx-debian.html
                EOF
}

resource "aws_instance" "terraform-instance2" {
  ami               = "ami-0d09654d0a20d3ae2"
  instance_type     = "t2.micro"
  availability_zone = "eu-west-2b"
  key_name          = "Barakat"
  subnet_id         = aws_subnet.subnet-2.id
  security_groups   = [aws_security_group.allow_web.id]
  tags = {
    Name = "instance2-terra"
  }
  user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update -y
                sudo apt-get install nginx -y
                sudo systemctl start nginx.service
                sudo systemctl enable nginx.service
                host=$(hostname)
                ip=$(ifconfig | grep 'inet ' | grep -v '127.0.0.1' | cut -c 7-17)
                sudo chown -R $USER:$USER /var/www
                echo 'Host name / IP address for this server is '$host'' > /var/www/html/index.nginx-debian.html
                EOF
}

resource "aws_instance" "terraform-instance3" {
  ami               = "ami-0d09654d0a20d3ae2"
  instance_type     = "t2.micro"
  availability_zone = "eu-west-2c"
  key_name          = "Barakat"
  subnet_id         = aws_subnet.subnet-3.id
  security_groups   = [aws_security_group.allow_web.id]
  tags = {
    Name = "instance3-terra"
  }
  user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update -y
                sudo apt-get install nginx -y
                sudo systemctl start nginx.service
                sudo systemctl enable nginx.service
                host=$(hostname)
                ip=$(ifconfig | grep 'inet ' | grep -v '127.0.0.1' | cut -c 7-17)
                sudo chown -R $USER:$USER /var/www
                echo 'Host name / IP address for this server is '$host'' > /var/www/html/index.nginx-debian.html
                EOF
}

# Create an Application Load Balancer

resource "aws_lb" "terraform-load-balancer" {
  name            = "loadbalancer-terra"
  internal        = false
  security_groups = [aws_security_group.terraform-load_balancer_sg.id]
  subnets         = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id, aws_subnet.subnet-3.id]

  enable_deletion_protection = false
  depends_on                 = [aws_instance.terraform-instance1, aws_instance.terraform-instance2, aws_instance.terraform-instance3]
}

# Create the target group

resource "aws_lb_target_group" "terraform-target-group" {
  name     = "target-group-terra"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.trial-vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Create the listener

resource "aws_lb_listener" "terraform-listener" {
  load_balancer_arn = aws_lb.terraform-load-balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terraform-target-group.arn
  }
}

# Create the listener rule

resource "aws_lb_listener_rule" "terraform-listener-rule" {
  listener_arn = aws_lb_listener.terraform-listener.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terraform-target-group.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}


# Attach the target group to the load balancer

resource "aws_lb_target_group_attachment" "target-group-attachment-terraform1" {
  target_group_arn = aws_lb_target_group.terraform-target-group.arn
  target_id        = aws_instance.terraform-instance1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "target-group-attachment-terraform2" {
  target_group_arn = aws_lb_target_group.terraform-target-group.arn
  target_id        = aws_instance.terraform-instance2.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "target-group-attachment-terraform3" {
  target_group_arn = aws_lb_target_group.terraform-target-group.arn
  target_id        = aws_instance.terraform-instance3.id
  port             = 80
}

resource "local_file" "ip_address" {
  filename = "/Users/user/Desktop/Altschool-mini-project/host-inventory"
  content  = <<EOT
  ${aws_instance.terraform-instance1.public_ip}
  ${aws_instance.terraform-instance2.public_ip}
  ${aws_instance.terraform-instance3.public_ip}
    EOT
}

# Route 53 and sub-domain name setup

resource "aws_route53_zone" "domain-name" {
  name = "omobola4all.me"
}

resource "aws_route53_zone" "sub-domain-name" {
  name = "terraform-test.omobola4all.me"

  tags = {
    Environment = "sub-domain-name"
  }
}

resource "aws_route53_record" "record" {
  zone_id = aws_route53_zone.domain-name.zone_id
  name    = "terraform-test.omobola4all.me"
  type    = "A"

  alias {
    name                   = aws_lb.terraform-load-balancer.dns_name
    zone_id                = aws_lb.terraform-load-balancer.zone_id
    evaluate_target_health = true
  }
  depends_on = [
    aws_lb.terraform-load-balancer
  ]
}
