resource "aws_vpc" "wordpress-vpc" {
  cidr_block           = var.vpc_cidr_block
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

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.wordpress-vpc.id
  availability_zone       = var.public_subnet_availability_zones[count.index]
  count                   = length(var.public_subnet_cidr_blocks)
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "wordpress-public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.wordpress-vpc.id
  availability_zone = var.private_subnet_availability_zones[count.index]
  count             = length(var.private_subnet_cidr_blocks)
  cidr_block        = var.private_subnet_cidr_blocks[count.index]

  tags = {
    Name = "wordpress-private-subnet-${count.index + 1}"
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

resource "aws_route_table_association" "public-subnet-association" {
  count          = length(var.public_subnet_cidr_blocks)
  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.wp-rt.id
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
  public_key = file(var.ssh_key_file)
}

resource "aws_instance" "wordpress-ec2" {
  ami                    = var.image_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[1].id
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name               = aws_key_pair.ssh-key.key_name
  user_data              = file(var.user_data_file)

  tags = {
    Name = "wordpress"
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = aws_subnet.private.*.id

  tags = {
    Name = "Wordpress DB subnet group"
  }
}

resource "aws_security_group" "rds-sg" {
  name        = "rds-sg"
  description = "Allow ssh connection"
  vpc_id      = aws_vpc.wordpress-vpc.id

  ingress {
    from_port       = var.db_ingress_from_port
    to_port         = var.db_ingress_to_port
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
  allocated_storage      = var.allocated_storage
  storage_type           = var.storage_type
  engine                 = var.engine
  engine_version         = var.engine_version
  instance_class         = var.db_instance_class
  name                   = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql5.7"
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds-sg.id]
}
