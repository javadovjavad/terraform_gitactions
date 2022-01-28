resource "aws_security_group" "instance" {
  name        = "spring-petclinic"
  description = "spring-petclinic security group"
  vpc_id     = aws_vpc.main.id

dynamic "ingress"{
  for_each = ["22","3306","8080"]
  content {
      description      = "ingress SSH from VPC"
      from_port        = ingress.value
      to_port          = ingress.value
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = []
      security_groups = []
      self = false
  }
}
  egress = [
    {
      description      = "Allow egress from VPC"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = []
      security_groups = []
      self = false
    }
  ]

  tags = {
    Name = "Dynamic security group"
    Project = "Terraform"
  }
}
