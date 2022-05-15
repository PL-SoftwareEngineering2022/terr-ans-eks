locals {
  public-subnet-name = "cali-subnet1"
  private-subnet-name = "cali-subnet2"
}

# VPC for the cali eks cluster
resource "aws_vpc" "cali-vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = var.vpc-name
  }
}

resource "aws_internet_gateway" "cali-igw" {
  vpc_id = aws_vpc.cali-vpc.id

  tags = {
    Name = var.igw-name
  }
}

#public subnet for cali-eks cluster
resource "aws_subnet" "cali-pub-subnet" {
  count      = length(var.pub_cidr_block)
  vpc_id     = aws_vpc.cali-vpc.id
  cidr_block = element(var.pub_cidr_block,count.index)

  tags = {
    Name = local.public-subnet-name
  }
}

#private subnet for cali-eks cluster
resource "aws_subnet" "cali-private-subnet" {
  count      = length(var.private_cidr_block)
  vpc_id     = aws_vpc.cali-vpc.id
  cidr_block = element(var.private_cidr_block,count.index)
  
  tags = {
    Name = local.private-subnet-name
  }
}
