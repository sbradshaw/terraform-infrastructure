provider aws {
  region = "eu-west-1"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable ip_addr {}
variable instance_type {}
# variable public_key_location {}

resource "aws_vpc" "app-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "app-subnet-1" {
  vpc_id = aws_vpc.app-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name: "${var.env_prefix}-subnet-1"
  }
}

# custom route table
# ------------------
# resource "aws_route_table" "app-route-table" {
#   vpc_id = aws_vpc.app-vpc.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.app-igw.id
#   }
#   tags = {
#      Name: "${var.env_prefix}-rtb"
#   }
# }

resource "aws_internet_gateway" "app-igw" {
  vpc_id = aws_vpc.app-vpc.id
  tags = {
     Name: "${var.env_prefix}-igw"
  }
}

# custom route table association
# ------------------------------
# resource "aws_route_table_association" "a-rtb-subnet" {
#   subnet_id = aws_subnet.app-subnet-1.id
#   route_table_id = aws_route_table.app-route-table.id
# }

resource "aws_default_route_table" "main-rtb" {
  default_route_table_id = aws_vpc.app-vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app-igw.id
  }
  tags = {
     Name: "${var.env_prefix}-main-rtb"
  }
}

resource "aws_security_group" "app-sg" {
  name = "app-sg"
  vpc_id = aws_vpc.app-vpc.id
  
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.ip_addr]
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
     Name: "${var.env_prefix}-sg"
  }
}

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

output "aws_ami_id" {
  value = data.aws_ami.latest-amazon-linux-image.id
}

output "ec2_public_ip" {
  value = aws_instance.app-server.public_ip
}

# automated key pair setup with id_rsa/id_rsa.pub
# resource "aws_key_pair" "ssh-key" {
#   key_name = "server-key"
#   public_key = file(var.public_key_location)
# }

resource "aws_instance" "app-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.app-subnet-1.id
  vpc_security_group_ids = [aws_security_group.app-sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  key_name = "ec2-keypair"
  # key_name = aws_key_pair.ssh-key.key_name

  user_data = file("entry-script.sh")

  tags = {
    Name = "${var.env_prefix}-server"
  }
}
