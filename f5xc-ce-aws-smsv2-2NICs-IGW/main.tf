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
    values = ["pveys-smsv2-public-3a"]
  }
}

data "aws_subnet" "inside" {
  vpc_id = data.aws_vpc.main.id
  filter {
    name   = "tag:Name"
    values = ["pveys-smsv2-private-3a"]
  }
}

#
#F5XC ressource (Site / Token / Cloud-init)
#
resource "volterra_securemesh_site_v2" "site" {
  name                    = format("%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex)
  namespace               = "system"
  description             = var.f5xc_sms_description
  block_all_services      = true
  logs_streaming_disabled = true
  enable_ha               = false
  labels = {
    "ves.io/provider" = "ves-io-AWS"
  }

  re_select {
    geo_proximity = true
  }

  aws {
    not_managed {}
  }
}

resource "volterra_token" "smsv2-token" {
  depends_on = [volterra_securemesh_site_v2.site]
  name       = format("%s-%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex, "token")
  namespace  = "system"
  type       = 1
  site_name  = volterra_securemesh_site_v2.site.name
}

data "cloudinit_config" "f5xc-ce_config" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = yamlencode({
      #cloud-config
      write_files = [
        {
          path        = "/etc/vpm/user_data"
          permissions = "0644"
          owner       = "root"
          content     = <<-EOT
            token: ${trimprefix(trimprefix(volterra_token.smsv2-token.id, "id="), "\"")}
          EOT
        }
      ]
    })
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
    description = "SSH from trusted"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["82.65.174.68/32"]
  }

  ingress {
    description = "ICMP from trusted"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["82.65.174.68/32"]
  }

  ingress {
    description = "IPSEC from any"
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
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
# CE interfaces creation. Comment / uncomment private_ips if you want or not use static IPs on the CEs
#
# Create a public network interface
resource "aws_network_interface" "public" {
    subnet_id = data.aws_subnet.outside.id
    security_groups = [aws_security_group.EC2-CE-sg-SLO.id]
    private_ips = [var.slo-private-ip]
    source_dest_check = false
    tags = {
        Name = format("%s-%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex,"eni-pub")
        owner = var.owner
    }
}

# Create a private network interface
resource "aws_network_interface" "private" {
    subnet_id = data.aws_subnet.inside.id
    security_groups = [aws_security_group.EC2-CE-sg-SLI.id]
    private_ips = [var.sli-private-ip]
    source_dest_check = false
    tags = {
        Name = format("%s-%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex,"eni-priv")
        owner = var.owner
    }
}

#
# Public IP creation
#
resource "aws_eip" "public_ip" {
  domain = "vpc"
}

resource "aws_eip_association" "eip_attach" {
  allocation_id        = aws_eip.public_ip.id
  network_interface_id = aws_network_interface.public.id
}

#
#Create the F5XC CE EC2 ressource
#
resource "aws_instance" "smsv2-aws-tf" {
  depends_on = [aws_security_group.EC2-CE-sg-SLI]
  ami                         = "ami-05f8f42b21a455447"
  instance_type               = "t3.2xlarge"
  key_name                    = var.aws-ssh-key
  network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.public.id
    }
    network_interface {
        device_index = 1
        network_interface_id = aws_network_interface.private.id
    }
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = 80
  }

  user_data = data.cloudinit_config.f5xc-ce_config.rendered

  tags = {
    Name                                         = format("%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex)
    ves-io-site-name                             = format("%s-%s", var.f5xc-ce-site-name, random_id.suffix.hex)
    "kubernetes.io/cluster/${var.f5xc-ce-site-name}-${random_id.suffix.hex}"   = "owned"
  }
}