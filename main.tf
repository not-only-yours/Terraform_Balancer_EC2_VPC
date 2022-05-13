
resource "aws_vpc" "prod-vpc" {
  cidr_block = "172.31.0.0/16"
  enable_dns_support = "true" #gives you an internal domain name
  enable_dns_hostnames = "true" #gives you an internal host name
  enable_classiclink = "false"
  instance_tenancy = "default"

  tags = {
    Name = "prod-vpc"
  }
}

resource "aws_subnet" "prod-subnet-public-1" {
  vpc_id = aws_vpc.prod-vpc.id
  cidr_block = "172.31.0.0/20"
  map_public_ip_on_launch = "true" //it makes this a public subnet
  availability_zone = "eu-west-2a"
  tags = {
    Name = "prod-subnet-public-1"
  }
}


resource "aws_subnet" "prod-subnet-public-2" {
  vpc_id = aws_vpc.prod-vpc.id
  cidr_block = "172.31.16.0/20"
  map_public_ip_on_launch = "true" //it makes this a public subnet
  availability_zone = "eu-west-2b"
  tags = {
    Name = "prod-subnet-public-2"
  }
}

resource "aws_subnet" "prod-subnet-public-3" {
  vpc_id = aws_vpc.prod-vpc.id
  cidr_block = "172.31.32.0/20"
  map_public_ip_on_launch = "true" //it makes this a public subnet
  availability_zone = "eu-west-2c"
  tags = {
    Name = "prod-subnet-public-3"
  }
}

resource "aws_internet_gateway" "prod-igw" {
  vpc_id = aws_vpc.prod-vpc.id
  tags = {
    Name = "prod-igw"
  }
}

resource "aws_route_table" "prod-public-crt" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    //associated subnet can reach everywhere
    cidr_block = "0.0.0.0/0"
    //CRT uses this IGW to reach internet
    gateway_id = aws_internet_gateway.prod-igw.id
  }

  tags = {
    Name = "prod-public-crt"
  }
}

resource "aws_route_table_association" "prod-crta-public-subnet-1"{
  subnet_id = aws_subnet.prod-subnet-public-1.id
  route_table_id = aws_route_table.prod-public-crt.id
}

resource "aws_security_group" "web-sg" {

  vpc_id = aws_vpc.prod-vpc.id

  name = "Nikita-sg"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_spot_instance_request" "EC2_Medium" {
  ami = "ami-0a244485e2e4ffd03"
  instance_type = "t2.medium"
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  key_name = "pair1"
  subnet_id = aws_subnet.prod-subnet-public-1.id
}

resource "aws_db_instance" "Nikitas_DB" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  name                 = "mydb"
  username             = "admin"
  password             = "nikitapassword"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

resource "aws_lb" "Nikitas_LB" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web-sg.id]
  subnets            = [aws_subnet.prod-subnet-public-1.id,
                        aws_subnet.prod-subnet-public-2.id,
                        aws_subnet.prod-subnet-public-3.id]


  enable_deletion_protection = false

#  access_logs {
#    bucket  = aws_s3_bucket.lb_logs.bucket
#    prefix  = "test-lb"
#    enabled = true
#  }

  tags = {
    Environment = "production"
  }
}