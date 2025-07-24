# VPC
resource "aws_vpc" "ndrs_vpc" {
  cidr_block       = "10.109.48.0/20"
  instance_tenancy = "default"
  tags = {
    Name = "ndrs-dev-vpc"
  }
}

# Subnet
resource "aws_subnet" "ndrs_dev_k8s_apne2_az1" {
  vpc_id            = aws_vpc.ndrs_vpc.id
  cidr_block        = "10.109.48.0/22"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "ndrs-dev-k8s-apne2-az1"
    "karpenter.sh/discovery" = var.eks-cluster-name
    "kubernetes.io/role/internal-elb": 1
    "kubernetes.io/cluster/${var.eks-cluster-name}" = "owned"
  }
}

resource "aws_subnet" "ndrs_dev_k8s_apne2_az3" {
  vpc_id            = aws_vpc.ndrs_vpc.id
  cidr_block        = "10.109.52.0/22"
  availability_zone = "ap-northeast-2c"
  tags = {
    Name = "ndrs-dev-k8s-apne2-az3"
    "karpenter.sh/discovery" = var.eks-cluster-name
    "kubernetes.io/role/internal-elb": 1
    "kubernetes.io/cluster/${var.eks-cluster-name}" = "owned"
  }
}

resource "aws_subnet" "ndrs_dev_dbs_apne2_az1" {
  vpc_id            = aws_vpc.ndrs_vpc.id
  cidr_block        = "10.109.56.0/25"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "ndrs-dev-dbs-apne2-az1"
    "karpenter.sh/discovery" = var.eks-cluster-name
    "kubernetes.io/role/internal-elb": 1
    "kubernetes.io/cluster/${var.eks-cluster-name}" = "owned"
  }
}

resource "aws_subnet" "ndrs_dev_dbs_apne2_az3" {
  vpc_id            = aws_vpc.ndrs_vpc.id
  cidr_block        = "10.109.56.128/25"
  availability_zone = "ap-northeast-2c"
  tags = {
    Name = "ndrs-dev-dbs-apne2-az3"
    "karpenter.sh/discovery" = var.eks-cluster-name
    "kubernetes.io/role/internal-elb": 1
    "kubernetes.io/cluster/${var.eks-cluster-name}" = "owned"
  }
}

resource "aws_subnet" "ndrs_dev_ec2_apne2_az1" {
  vpc_id            = aws_vpc.ndrs_vpc.id
  cidr_block        = "10.109.57.0/27"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "ndrs-dev-ec2-apne2-az1"
    "karpenter.sh/discovery" = var.eks-cluster-name
    "kubernetes.io/role/internal-elb": 1
    "kubernetes.io/cluster/${var.eks-cluster-name}" = "owned"
  }
}

resource "aws_subnet" "ndrs_dev_ec2_apne2_az3" {
  vpc_id            = aws_vpc.ndrs_vpc.id
  cidr_block        = "10.109.57.32/27"
  availability_zone = "ap-northeast-2c"
  tags = {
    Name = "ndrs-dev-ec2-apne2-az3"
    "karpenter.sh/discovery" = var.eks-cluster-name
    "kubernetes.io/role/internal-elb": 1
    "kubernetes.io/cluster/${var.eks-cluster-name}" = "owned"
  }
}

resource "aws_subnet" "ndrs_dev_int_elb_apne2_az1" {
  vpc_id            = aws_vpc.ndrs_vpc.id
  cidr_block        = "10.109.57.64/27"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "ndrs-dev-int-elb-apne2-az1"
    "karpenter.sh/discovery" = var.eks-cluster-name
    "kubernetes.io/role/internal-elb": 1
    "kubernetes.io/cluster/${var.eks-cluster-name}" = "owned"
  }
}

resource "aws_subnet" "ndrs_dev_int_elb_apne2_az3" {
  vpc_id            = aws_vpc.ndrs_vpc.id
  cidr_block        = "10.109.57.96/27"
  availability_zone = "ap-northeast-2c"
  tags = {
    Name = "ndrs-dev-int-elb-apne2-az3"
    "karpenter.sh/discovery" = var.eks-cluster-name
    "kubernetes.io/role/internal-elb": 1
    "kubernetes.io/cluster/${var.eks-cluster-name}" = "owned"
  }
}

resource "aws_subnet" "ndrs_dev_k8s_elb_apne2_az1" {
  vpc_id            = aws_vpc.ndrs_vpc.id
  cidr_block        = "10.109.57.128/27"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "ndrs-dev-k8s-elb-apne2-az1"
    "kubernetes.io/role/elb": 1
    "kubernetes.io/cluster/${var.eks-cluster-name}" = "owned"
  }
}

resource "aws_subnet" "ndrs_dev_k8s_elb_apne2_az3" {
  vpc_id            = aws_vpc.ndrs_vpc.id
  cidr_block        = "10.109.57.160/27"
  availability_zone = "ap-northeast-2c"
  tags = {
    Name = "ndrs-dev-k8s-elb-apne2-az3"
    "kubernetes.io/role/elb": 1
    "kubernetes.io/cluster/${var.eks-cluster-name}" = "owned"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "ndrs_igw" {
  vpc_id = aws_vpc.ndrs_vpc.id
  tags = {
    Name = "ndrs-igw"
  }
}

# NAT Gateway
resource "aws_eip" "ndrs_eip_nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.ndrs_igw]
  tags = {
    Name = "ndrs-eip-nat"
  }
}

resource "aws_nat_gateway" "ndrs_nat" {
  subnet_id     = aws_subnet.ndrs_dev_k8s_elb_apne2_az1.id
  allocation_id = aws_eip.ndrs_eip_nat.id
  depends_on    = [aws_internet_gateway.ndrs_igw]
  tags = {
    Name = "ndrs-nat"
  }
}

# Routing Table
resource "aws_route_table" "ndrs_dev_k8s_apne2_rt" {
  vpc_id = aws_vpc.ndrs_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ndrs_nat.id
  }
  tags = {
    Name = "ndrs-dev-k8s-apne2-rt"
  }
  lifecycle {
    ignore_changes = [route]
  }
}

resource "aws_route_table_association" "ndrs_dev_k8s_apne2_az1_rt" {
  subnet_id      = aws_subnet.ndrs_dev_k8s_apne2_az1.id
  route_table_id = aws_route_table.ndrs_dev_k8s_apne2_rt.id
}

resource "aws_route_table_association" "ndrs_dev_k8s_apne2_az3_rt" {
  subnet_id      = aws_subnet.ndrs_dev_k8s_apne2_az3.id
  route_table_id = aws_route_table.ndrs_dev_k8s_apne2_rt.id
}

resource "aws_route_table" "ndrs_dev_dbs_apne2_rt" {
  vpc_id = aws_vpc.ndrs_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ndrs_nat.id
  }
  tags = {
    Name = "ndrs-dev-dbs-apne2-rt"
  }
  lifecycle {
    ignore_changes = [route]
  }
}

resource "aws_route_table_association" "ndrs_dev_dbs_apne2_az1_rt" {
  subnet_id      = aws_subnet.ndrs_dev_dbs_apne2_az1.id
  route_table_id = aws_route_table.ndrs_dev_dbs_apne2_rt.id
}

resource "aws_route_table_association" "ndrs_dev_dbs_apne2_az3_rt" {
  subnet_id      = aws_subnet.ndrs_dev_dbs_apne2_az3.id
  route_table_id = aws_route_table.ndrs_dev_dbs_apne2_rt.id
}

resource "aws_route_table" "ndrs_dev_ec2_apne2_rt" {
  vpc_id = aws_vpc.ndrs_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ndrs_nat.id
  }
  tags = {
    Name = "ndrs-dev-ec2-apne2-rt"
  }
  lifecycle {
    ignore_changes = [route]
  }
}

resource "aws_route_table_association" "ndrs_dev_ec2_apne2_az1_rt" {
  subnet_id      = aws_subnet.ndrs_dev_ec2_apne2_az1.id
  route_table_id = aws_route_table.ndrs_dev_ec2_apne2_rt.id
}

resource "aws_route_table_association" "ndrs_dev_ec2_apne2_az3_rt" {
  subnet_id      = aws_subnet.ndrs_dev_ec2_apne2_az3.id
  route_table_id = aws_route_table.ndrs_dev_ec2_apne2_rt.id
}

resource "aws_route_table" "ndrs_dev_int_elb_apne2_rt" {
  vpc_id = aws_vpc.ndrs_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ndrs_nat.id
  }
  tags = {
    Name = "ndrs-dev-int-elb-apne2-rt"
  }
  lifecycle {
    ignore_changes = [route]
  }
}

resource "aws_route_table_association" "ndrs_dev_int_elb_apne2_az1_rt" {
  subnet_id      = aws_subnet.ndrs_dev_int_elb_apne2_az1.id
  route_table_id = aws_route_table.ndrs_dev_int_elb_apne2_rt.id
}

resource "aws_route_table_association" "ndrs_dev_int_elb_apne2_az3_rt" {
  subnet_id      = aws_subnet.ndrs_dev_int_elb_apne2_az3.id
  route_table_id = aws_route_table.ndrs_dev_int_elb_apne2_rt.id
}

resource "aws_route_table" "ndrs_dev_k8s_elb_apne2_rt" {
  vpc_id = aws_vpc.ndrs_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ndrs_igw.id
  }
  tags = {
    Name = "ndrs-dev-k8s-elb-apne2-rt"
  }
  lifecycle {
    ignore_changes = [route]
  }
}

resource "aws_route_table_association" "ndrs_dev_k8s_elb_apne2_az1_rt" {
  subnet_id      = aws_subnet.ndrs_dev_k8s_elb_apne2_az1.id
  route_table_id = aws_route_table.ndrs_dev_k8s_elb_apne2_rt.id
}

resource "aws_route_table_association" "ndrs_dev_k8s_elb_apne2_az3_rt" {
  subnet_id      = aws_subnet.ndrs_dev_k8s_elb_apne2_az3.id
  route_table_id = aws_route_table.ndrs_dev_k8s_elb_apne2_rt.id
}