resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "myvpc"
  }
}

resource "aws_subnet" "public_subnet1" {
  availability_zone = "us-east-1a"
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.0.0/24"

  tags = {
    Name = "public-subnet1"
  }
}

resource "aws_subnet" "public_subnet2" {
  availability_zone = "us-east-1b"
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.2.0/24"

  tags = {
    Name = "public-subnet2"
  }
}

resource "aws_subnet" "private_subnet" {
  availability_zone = "us-east-1b"
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.1.0/24"

  tags = {
    Name = "private-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "igw"
  }
}

resource "aws_route_table" "public_route_table1" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table1"
  }
}


resource "aws_route_table" "public_route_table2" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table2"
  }
}


resource "aws_route_table_association" "public-and-route1" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.public_route_table1.id
}

resource "aws_route_table_association" "public-and-route2" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.public_route_table2.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet1.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private-and-route" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}