terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0" #this require at least 1.2.0 of terraform version
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my_vpc"
  }
}

resource "aws_subnet" "public_subnet_east_1a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_east-1a"
  }
}

resource "aws_subnet" "public_subnet_east_1b" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_east-1b"
  }
}

resource "aws_subnet" "private_subnet_east_1a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private_subnet_east-1a"
  }
}

resource "aws_subnet" "private_subnet_east_1b" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "private_subnet_east-1b"
  }
}

data "aws_ami" "my_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_security_group" "instance_security_group" {
  name        = "instance_SecurityGroup"
  description = "Security group for EC2 to open port 80 from anywhere"
  vpc_id      = aws_vpc.my_vpc.id

  // Allow inbound HTTP traffic from anywhere (public access)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow access from any IP address
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "InstanceSecurityGroup"
  }
}

# EC2 Instance 1 in public subnet in us-east-1a
resource "aws_instance" "public_instance_1" {
  ami                    = data.aws_ami.my_ami.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet_east_1a.id
  vpc_security_group_ids = [aws_security_group.instance_security_group.id]
  tags = {
    Name = var.instance1_name
  }
}

# EC2 Instance 2 in public subnet in us-east-1b
resource "aws_instance" "public_instance_2" {
  ami                    = data.aws_ami.my_ami.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet_east_1b.id
  vpc_security_group_ids = [aws_security_group.instance_security_group.id]
  tags = {
    Name = var.instance2_name
  }
}

# DB Subnet Group for rds (Use private subnets)
resource "aws_db_subnet_group" "subnet_group" {
  name       = "rds_subnet_group"
  subnet_ids = [aws_subnet.private_subnet_east_1a.id, aws_subnet.private_subnet_east_1b.id]

  tags = {
    Name = "My DB subnet group"
  }
}

# rds security group for opening port 3306 to only web servers security group
resource "aws_security_group" "rds_security_group" {
  name        = "rds_SecurityGroup"
  description = "rds Security group opens port 3306 to only web servers security group"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.instance_security_group.id]
    description     = "Allow inbound MySQL traffic from web servers"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds_SecurityGroup"
  }
}

# rds Database Instance in Private Subnets
resource "aws_db_instance" "rds_database" {
  allocated_storage      = 10
  db_name                = "mysql_rds_db"
  db_subnet_group_name   = aws_db_subnet_group.subnet_group.name
  engine                 = "mysql"
  engine_version         = "8.0"
  identifier             = "mysql-instance"
  instance_class         = "db.t3.micro"
  multi_az               = false
  username               = "test"
  password               = "test-passwords"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]
}