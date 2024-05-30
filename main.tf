terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

#Region
provider "aws" {
  region = var.aws_region
}

#VPC
resource "aws_vpc" "myVPC" {
  cidr_block = var.cidr_block
}

#Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "IGW"
  }
}

#Route table
resource "aws_route_table" "devineRT" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "DevineRT"
  }
}

#Route table associations
resource "aws_route_table_association" "subnet_association1" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.devineRT.id
}

resource "aws_route_table_association" "subnet_association2" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.devineRT.id
}

#Subnets
resource "aws_subnet" "public_subnet1" {
  vpc_id                  = aws_vpc.myVPC.id
  cidr_block              = var.subnet1_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.az1

  tags = {
    Name = "PublicSubnet1"
  }
}

resource "aws_subnet" "public_subnet2" {
  vpc_id                  = aws_vpc.myVPC.id
  cidr_block              = var.subnet2_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.az2

  tags = {
    Name = "PublicSubnet2"
  }
}

#security group for ec2
resource "aws_security_group" "EC2SG" {
  name        = "devineEC2SG"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "devineEC2SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4_ec2" {
  security_group_id = aws_security_group.EC2SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_ec2" {
  security_group_id = aws_security_group.EC2SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


#security group for alb
resource "aws_security_group" "ALBSG" {
  name        = "devineALBSG"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "devineALBSG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4_alb" {
  security_group_id = aws_security_group.ALBSG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_alb" {
  security_group_id = aws_security_group.ALBSG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


#security group for rds
resource "aws_security_group" "RDSSG" {
  name        = "devineRDSSG"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "devineRDSSG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4_rds" {
  security_group_id = aws_security_group.RDSSG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 3306
  ip_protocol       = "tcp"
  to_port           = 3306
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_rds" {
  security_group_id = aws_security_group.RDSSG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#launch configuration Template 
resource "aws_launch_configuration" "webteir_dev" {
  name_prefix                 = "webteir_dev"
  image_id                    = var.ami_id
  instance_type               = var.instance_type
  security_groups             = [aws_security_group.EC2SG.id]
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "my_asg" {
  name                 = "terraform-asg-devine"
  launch_configuration = aws_launch_configuration.webteir_dev.id
  min_size             = var.autoscaling_group_min_size
  max_size             = var.autoscaling_group_max_size
  desired_capacity     = var.capacity_desired
  #target_group_arns    = ["${aws_lb_target_group.ALBTG.arn}"]
  vpc_zone_identifier = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]

  lifecycle {
    create_before_destroy = true
  }
}

# Target Group
resource "aws_lb_target_group" "ALBTG" {
  name     = "ALBTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myVPC.id
}

resource "aws_lb" "web_alb" {
  name               = "Devineapp-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ALBSG.id]
  subnets            = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]


  tags = {
    Environment = "lab"
  }
}

# Create an AWS Glue Job
resource "aws_glue_job" "my_glue_job" {
  name     = "my-glue-job"
  role_arn = aws_iam_role.my_role.arn
  command {
    name            = "glueetl"
    script_location = "s3://path/to/glue/script.py"
  }
}

# Create a KMS Key
resource "aws_kms_key" "my_kms_key" {
  description             = "My KMS Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

# lb listener
resource "aws_lb_listener" "my_alb_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ALBTG.arn
  }
}

#s3 bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "metroc-delicia-2020-afe"

  tags = {
    Name        = "Devine Bucket"
    Environment = "Dev"
  }
}

# IAM Role
resource "aws_iam_role" "my_role" {
  name = "my_role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Principal" : {
        "Service" : "ec2.amazonaws.com"
      },
      "Action" : "sts:AssumeRole"
    }]
  })
}

# IAM Policy
resource "aws_iam_role_policy" "devine_policy" {
  name = "devine-policy"
  role = aws_iam_role.my_role.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Action" : "s3:*",
      "Resource" : "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attachment" {
  role       = aws_iam_role.my_role.name
  policy_arn = aws_iam_role_policy.devine_policy.name //arn
}

# RDS Subnet Group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]
}

# RDS Instance
resource "aws_db_instance" "my_db_instance" {
  identifier             = "my-db-instance"
  allocated_storage      = 10
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  db_name                = "devinemysqldb"
  username               = "myuser"
  password               = "mypassword"
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.RDSSG.id]
  skip_final_snapshot    = true
}
