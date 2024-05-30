variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet1_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "subnet2_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "az1" {
  type    = string
  default = "us-east-1a"
}
variable "az2" {
  type    = string
  default = "us-east-1b"
}

variable "ami_id" {
  type    = string
  default = "ami-0d94353f7bad10668"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "autoscaling_group_min_size" {
  type    = number
  default = 2
}

variable "autoscaling_group_max_size" {
  type    = number
  default = 4
}

variable "capacity_desired" {
  type    = number
  default = 2
}
