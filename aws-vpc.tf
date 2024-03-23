data "aws_vpc" "fiap" {
  tags = {
    "fiap-vpc" = true
  }
}

data "aws_subnets" "fiap_private" {
  tags = {
    "fiap-private-subnet" = true
  }
}

data "aws_security_group" "lb_ingress" {
  name = "fiap-lb-ingress"
}

resource "aws_security_group" "app" {
  name        = format("%s-sg", var.app_name)
  description = "allows app traffic"
  vpc_id      = data.aws_vpc.fiap.id

  ingress {
    description     = "app port"
    from_port       = var.app_docker_port
    to_port         = var.app_docker_port
    protocol        = "tcp"
    cidr_blocks     = [data.aws_vpc.fiap.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
