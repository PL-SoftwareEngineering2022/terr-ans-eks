locals {
  public-subnet-name    = "cali-subnet1"
  private-subnet-name   = "cali-subnet2"
  avail_zone            = ["us-west-1a", "us-west-1b"]
  pub-route-table       = "cali-public-RT"
  private-route-table   = "cali-private-RT"
  public-RT-assoc       = "cali-public RTA"
  private-RT-assoc      = "cali-private-RTA"
}

# VPC for the cali eks cluster
resource "aws_vpc" "cali-vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = var.vpc-name
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
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
  availability_zone = element(local.avail_zone,count.index)

  tags = {
    Name = local.public-subnet-name
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb" = 1

  }
}

#private subnet for cali-eks cluster
resource "aws_subnet" "cali-private-subnet" {
  count      = length(var.private_cidr_block)
  vpc_id     = aws_vpc.cali-vpc.id
  cidr_block = element(var.private_cidr_block,count.index) # element helps map/apply the values correspondingly
  availability_zone = element(local.avail_zone,count.index)

  tags = {
    Name = local.private-subnet-name
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_nat_gateway" "cali-nat-gw" {
  subnet_id     = aws_subnet.cali-pub-subnet[0].id # nat gateway is attached to one public subnet. 

  tags = {
    Name = "cali-nat-gw"
  }

  /* To ensure proper ordering, it is recommended to add an explicit dependency
  on the Internet Gateway for the VPC.*/
  depends_on = [aws_internet_gateway.cali-igw]
}

#public Route Table and Route Table Association
resource "aws_route_table" "cali-public-RT" {
  vpc_id = aws_vpc.cali-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cali-igw.id
  }

  tags = {
    Name = local.pub-route-table
  }
}

resource "aws_route_table_association" "cali-public-RTA" {
  gateway_id     = aws_internet_gateway.cali-igw.id 
  # count        = length(var.pub_cidr_block)
  # subnet_id    = element(aws_subnet.cali-pub-subnet.*.id,count.index)
  #The gateway ID to create an association. Conflicts with subnet_id.
  route_table_id = aws_route_table.cali-private-RT.id
}

# Private Route Table and Route Table Association
resource "aws_route_table" "cali-private-RT" {
  vpc_id = aws_vpc.cali-vpc.id

  route {
    cidr_block     = var.vpc_cidr
    nat_gateway_id = aws_nat_gateway.cali-nat-gw.id
  }

  tags = {
    Name = local.private-route-table
  }
}

resource "aws_route_table_association" "cali-private-RTA" {
  gateway_id     = aws_nat_gateway.cali-nat-gw.id 
  # count        = length(local.avail_zone)
  # subnet_id    = element(aws_subnet.cali-private-subnet.*.id,count.index)
  #The gateway ID to create an association. Conflicts with subnet_id.
  route_table_id = aws_route_table.cali-private-RT.id
}

# notes:
# you have to have a count to utilize a count index; see resource- subnet above