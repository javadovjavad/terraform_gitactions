provider "aws" {
   region = "eu-west-1"
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "javad-j-bucket"
    key    = "network/terraform.tfstate"
    region = "eu-west-1"
  }
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags={
    Name = "main vpc"
    Env = "Development"
  }
}

 ################# Subnets #############
resource "aws_subnet" "private_subnet" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-1a"


  tags={
    Name = "Private-subnet-1"
    Env = "Development"
    }
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-west-1c"
  map_public_ip_on_launch = true


  tags={
    Name = "Public-subnet-1"
    Env = "Development"
  }
}

######## IGW ###############
resource "aws_internet_gateway" "main-igw" {
  vpc_id = "${aws_vpc.main.id}"

  tags={
    Name = "main-igw"
    Env = "Development"
  }
}

########### NAT ##############
resource "aws_eip" "nat" {
}

resource "aws_nat_gateway" "main-natgw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.public_subnet.id}"

  tags={
    Name = "main-nat"
    Env = "Development"
  }
}

############# Route Tables ##########

resource "aws_route_table" "main-public-rt" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main-igw.id}"
  }

  tags={
    Name = "main-public-rt"
    Env = "Development"
  }
}

resource "aws_route_table" "main-private-rt" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.main-natgw.id}"
  }

  tags={
    Name = "main-private-rt"
    Env = "Development"
  }
}

######### PUBLIC Subnet assiosation with rotute table    ######
resource "aws_route_table_association" "public-assoc-1" {
  subnet_id      = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.main-public-rt.id}"
}


########## PRIVATE Subnets assiosation with rotute table ######
resource "aws_route_table_association" "private-assoc-1" {
  subnet_id      = "${aws_subnet.private_subnet.id}"
  route_table_id = "${aws_route_table.main-private-rt.id}"
}

