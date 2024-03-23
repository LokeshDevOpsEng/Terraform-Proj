#creating a vpc with cidr range - 10.0.0.0/16
resource "aws_vpc" "vpc" {
  cidr_block = var.cidr
  tags = {
    Name = "tf-vpc"
  }
}
#creating two subnets in availablity zone 1a and 1b in ap-south-1 region
resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.sub1-cidr #cidr range = 10.0.0.0/24
  availability_zone       = var.available-zone-1
  map_public_ip_on_launch = true
  tags = {
    Name = "tf-public-subnet-1"
  }
}
resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.sub2-cidr #cidr range= 10.0.4.0/24
  availability_zone       = var.available-zone-2
  map_public_ip_on_launch = true
  tags = {
    Name = "tf-public-subnet-2"
  }
}
#creating internet_gateway for subnet accessing internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "tf-igw"
  }
}
#creating routetable in the above vpc and attaching igw
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}
#associating the igw with subnets
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.rt.id
}
resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.rt.id
}
#creating security group with inbound and outbound rules
resource "aws_security_group" "websg" {
  name   = "web"
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "tf-web-sg"
  }
}
#creating s3 bucket and enabling versioning
resource "aws_s3_bucket" "s3" {
  bucket = "lokeshterraformproject"
}
resource "aws_s3_bucket_versioning" "s3-v" {
  bucket = aws_s3_bucket.s3.id
  versioning_configuration {
    status = "Enabled"
  }
}
#creating 2 instances in 2 public subnets
resource "aws_instance" "webserver1" {
  ami                    = var.ami-id
  instance_type          = var.instance-type
  vpc_security_group_ids = [aws_security_group.websg.id]
  subnet_id              = aws_subnet.sub1.id
  user_data              = base64encode(file("startup1.sh"))
  tags = {
    Name = "tf-ec2-webserver-1"
  }
}
resource "aws_instance" "webserver2" {
  ami                    = var.ami-id
  instance_type          = var.instance-type
  vpc_security_group_ids = [aws_security_group.websg.id]
  subnet_id              = aws_subnet.sub2.id
  user_data              = base64encode(file("startup2.sh"))
  tags = {
    Name = "tf-ec2-webserver-2"
  }
}
#creating application loadbalancer for traffic routing into instances
resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.websg.id]
  subnets         = [aws_subnet.sub1.id, aws_subnet.sub2.id]

  tags = {
    Name = "tf-alb"
  }
}
#creating target-group for alb
resource "aws_lb_target_group" "alb-tg" {
  name     = "tf-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
  health_check {
    path = "/"
    port = "traffic-port"
  }
}
#attaching the instances to target-group
resource "aws_lb_target_group_attachment" "alb-tg-a-1" {
  target_group_arn = aws_lb_target_group.alb-tg.arn
  target_id        = aws_instance.webserver1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "alb-tg-a-2" {
  target_group_arn = aws_lb_target_group.alb-tg.arn
  target_id        = aws_instance.webserver2.id
  port             = 80
}
#adding listener to the alb
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.alb-tg.arn
    type             = "forward"
  }
}
