resource "aws_vpc" "wordpress-vpc" {
  cidr_block           = "10.121.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "wordpress-vpc"
  }
}

# EC2 or elastic ip should depends on igw
resource "aws_internet_gateway" "worpdress_igw" {
  vpc_id = aws_vpc.wordpress-vpc.id

  tags = {
    Name = "wordpress_igw"
  }
}

resource "aws_subnet" "public-subnet-1" {
  vpc_id                  = aws_vpc.wordpress-vpc.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.121.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "wordpress-public-subnet-1"
  }
}

resource "aws_subnet" "public-subnet-2" {
  vpc_id                  = aws_vpc.wordpress-vpc.id
  availability_zone       = "us-east-1b"
  cidr_block              = "10.121.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "wordpress-public-subnet-2"
  }
}

resource "aws_subnet" "public-subnet-3" {
  vpc_id                  = aws_vpc.wordpress-vpc.id
  availability_zone       = "us-east-1c"
  cidr_block              = "10.121.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "wordpress-public-subnet-3"
  }
}

resource "aws_subnet" "private-subnet-1" {
  vpc_id                  = aws_vpc.wordpress-vpc.id
  availability_zone       = "us-east-1d"
  cidr_block              = "10.121.3.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "wordpress-private-subnet-1"
  }
}

resource "aws_subnet" "private-subnet-2" {
  vpc_id                  = aws_vpc.wordpress-vpc.id
  availability_zone       = "us-east-1e"
  cidr_block              = "10.121.4.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "wordpress-private-subnet-2"
  }
}

resource "aws_subnet" "private-subnet-3" {
  vpc_id                  = aws_vpc.wordpress-vpc.id
  availability_zone       = "us-east-1f"
  cidr_block              = "10.121.5.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "wordpress-private-subnet-3"
  }
}

resource "aws_route_table" "wp-rt" {
  vpc_id = aws_vpc.wordpress-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.worpdress_igw.id
  }

  tags = {
    Name = "wordpress-route-table"
  }
}

resource "aws_route_table_association" "association-1" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.wp-rt.id
}
resource "aws_route_table_association" "association-2" {
  subnet_id      = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.wp-rt.id
}
resource "aws_route_table_association" "association-3" {
  subnet_id      = aws_subnet.public-subnet-3.id
  route_table_id = aws_route_table.wp-rt.id
}

variable "ingress_ports" {
  type    = list(number)
  default = [80, 443, 22]
}

resource "aws_security_group" "sg" {
  name        = "sg"
  description = "Allow ssh connection"
  vpc_id      = aws_vpc.wordpress-vpc.id

  dynamic "ingress" {
    iterator = iport
    for_each = var.ingress_ports
    content {
      from_port   = iport.value
      to_port     = iport.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.wordpress-vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wordpress-sg"
  }
}

resource "aws_key_pair" "ssh-key" {
  key_name   = "wordpress-pub-key"
  public_key = file("ec2-wp.pub")
}

resource "aws_instance" "wordpress-ec2" {
  ami                    = "ami-0323c3dd2da7fb37d"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public-subnet-1.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name               = aws_key_pair.ssh-key.key_name
  user_data              = file("userdata.sh")

  tags = {
    Name = "wordpress"
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.private-subnet-1.id, aws_subnet.private-subnet-2.id, aws_subnet.private-subnet-3.id]

  tags = {
    Name = "Wordpress DB subnet group"
  }
}

resource "aws_security_group" "rds-sg" {
  name        = "rds-sg"
  description = "Allow ssh connection"
  vpc_id      = aws_vpc.wordpress-vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wordpress-rds-sg"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  name                   = "mydb"
  username               = "admin"
  password               = "adminadmin"
  parameter_group_name   = "default.mysql5.7"
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds-sg.id]
}
