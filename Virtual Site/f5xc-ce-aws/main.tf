#Random generator
resource "random_id" "suffix" {
  byte_length = 2
}

#
#Get AWS VPC and subnets
#
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnet" "outside" {
  vpc_id = data.aws_vpc.main.id
  filter {
    name   = "tag:Name"
    values = [var.outside_subnet_name]
  }
}

data "aws_subnet" "inside" {
  vpc_id = data.aws_vpc.main.id
  filter {
    name   = "tag:Name"
    values = [var.inside_subnet_name]
  }
}

data "aws_subnet" "nlb_public" {
  vpc_id = data.aws_vpc.main.id
  filter {
    name   = "tag:Name"
    values = [var.nlb_public_subnet_name]
  }
}

#
#AWS security group for the instance
#
resource "aws_security_group" "EC2-CE-sg-SLO" {
  name        = format("%s-%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex,"sg-SLO")
  description = "Allow traffic flows on SLO"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = format("%s-%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex,"sg-SLO")
    owner = var.owner
  }
}

resource "aws_security_group" "EC2-CE-sg-SLI" {
  name        = format("%s-%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex,"sg-SLI")
  description = "Allow traffic flows on SLI"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = format("%s-%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex,"sg-SLI")
    owner = var.owner
  }
}

#
# CE interfaces creation. Using dynamic IP allocation with NAT Gateway
#
# Create outside network interfaces (private - using NAT Gateway for outbound)
resource "aws_network_interface" "outside" {
    count       = var.node_count
    subnet_id   = data.aws_subnet.outside.id
    security_groups = [aws_security_group.EC2-CE-sg-SLO.id]
    source_dest_check = false
    tags = {
        Name = format("%s-%s-%s-%02d", var.f5xc-ce-site-name, random_id.suffix.hex,"eni-outside", count.index + 1)
        owner = var.owner
    }
}

# Create inside network interfaces (private)
resource "aws_network_interface" "inside" {
    count       = var.node_count
    subnet_id   = data.aws_subnet.inside.id
    security_groups = [aws_security_group.EC2-CE-sg-SLI.id]
    source_dest_check = false
    tags = {
        Name = format("%s-%s-%s-%02d", var.f5xc-ce-site-name, random_id.suffix.hex,"eni-inside", count.index + 1)
        owner = var.owner
    }
}

#
# No Elastic IPs needed - using NAT Gateway for outbound connectivity
#

#
#Create the F5XC CE EC2 ressources
#
resource "aws_instance" "smsv2-aws-tf" {
  count      = var.node_count
  depends_on = [aws_security_group.EC2-CE-sg-SLI]
  ami                         = var.aws-f5xc-ami
  instance_type               = var.aws-ec2-flavor
  key_name                    = var.aws-ssh-key
  network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.outside[count.index].id
    }
    network_interface {
        device_index = 1
        network_interface_id = aws_network_interface.inside[count.index].id
    }
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = 80
  }

  user_data = data.cloudinit_config.f5xc-ce_config[count.index].rendered

  tags = {
    Name                                         = format("%s-%s-%02d", var.f5xc-ce-site-name, random_id.suffix.hex, count.index + 1)
    ves-io-site-name                             = format("%s-%s-%02d", var.f5xc-ce-site-name, random_id.suffix.hex, count.index + 1)
    "kubernetes.io/cluster/${var.f5xc-ce-site-name}-${random_id.suffix.hex}-${format("%02d", count.index + 1)}"   = "owned"
    owner = var.owner
  }
}

#
# Security group for Network Load Balancer
#
resource "aws_security_group" "nlb_sg" {
  name        = format("%s-%s-nlb-sg", var.f5xc-ce-site-name, random_id.suffix.hex)
  description = "Security group for NLB - Allow only HTTP and HTTPS"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = format("%s-%s-nlb-sg", var.f5xc-ce-site-name, random_id.suffix.hex)
    owner = var.owner
  }
}

#
# Network Load Balancer resources
#
resource "aws_lb" "nlb" {
  count              = var.deploy_nlb ? 1 : 0
  name               = format("%s-%s-nlb", var.f5xc-ce-site-name, random_id.suffix.hex)
  internal           = false
  load_balancer_type = "network"
  subnets            = [data.aws_subnet.nlb_public.id]
  security_groups    = [aws_security_group.nlb_sg.id]

  enable_deletion_protection = false

  tags = {
    Name  = format("%s-%s-nlb", var.f5xc-ce-site-name, random_id.suffix.hex)
    owner = var.owner
  }
}

resource "aws_lb_target_group" "nlb_tg" {
  count       = var.deploy_nlb ? length(var.nlb_target_ports) : 0
  name        = format("%s-tg-%d", random_id.suffix.hex, var.nlb_target_ports[count.index])
  port        = var.nlb_target_ports[count.index]
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    port                = var.nlb_health_check_port
    protocol            = "TCP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name  = format("%s-%s-tg-%d", var.f5xc-ce-site-name, random_id.suffix.hex, var.nlb_target_ports[count.index])
    owner = var.owner
  }
}

resource "aws_lb_listener" "nlb_listener" {
  count             = var.deploy_nlb ? length(var.nlb_target_ports) : 0
  load_balancer_arn = aws_lb.nlb[0].arn
  port              = var.nlb_target_ports[count.index]
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_tg[count.index].arn
  }
}

resource "aws_lb_target_group_attachment" "nlb_attachment" {
  count            = var.deploy_nlb ? var.node_count * length(var.nlb_target_ports) : 0
  target_group_arn = aws_lb_target_group.nlb_tg[count.index % length(var.nlb_target_ports)].arn
  target_id        = aws_network_interface.outside[floor(count.index / length(var.nlb_target_ports))].private_ip
  port             = var.nlb_target_ports[count.index % length(var.nlb_target_ports)]
}