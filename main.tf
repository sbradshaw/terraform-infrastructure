#  main.tf

terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket = "app-bucket-ctcba"
    key = "app/state.tfstate"
    region = "eu-west-1"
  }
  
}

resource "aws_vpc" "app-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "${var.env_prefix}-vpc"
  }
}

module "app-subnet" {
  source = "./modules/subnet"
  subnet_cidr_block = var.subnet_cidr_block
  avail_zone = var.avail_zone
  env_prefix = var.env_prefix
  vpc_id = aws_vpc.app-vpc.id
  default_route_table_id = aws_vpc.app-vpc.default_route_table_id
}

module "app-webserver" {
  source = "./modules/webserver"
  vpc_id = aws_vpc.app-vpc.id
  ip_addr = var.ip_addr
  env_prefix = var.env_prefix
  image_name = var.image_name
  instance_type = var.instance_type
  subnet_id = module.app-subnet.subnet.id
  avail_zone = var.avail_zone
}
