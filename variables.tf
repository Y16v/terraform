variable "region" {
  type    = string
  default = "us-east-1"
}


variable "vpc_cidr_block" {
  type    = string
  default = "10.121.0.0/16"
}

variable "public_subnet_availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnet_availability_zones" {
  type    = list(string)
  default = ["us-east-1d", "us-east-1e", "us-east-1f"]
}

variable "public_subnet_cidr_blocks" {
  type    = list(string)
  default = ["10.121.0.0/24", "10.121.1.0/24", "10.121.2.0/24"]
}

variable "private_subnet_cidr_blocks" {
  type    = list(string)
  default = ["10.121.3.0/24", "10.121.4.0/24", "10.121.5.0/24"]
}

variable "ingress_ports" {
  type    = list(number)
  default = [80, 443, 22]
}

variable "ssh_key_file" {
  type = string
}

variable "user_data_file" {
  type = string
}

variable "image_id" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "db_ingress_from_port" {
  type    = number
  default = 3306
}

variable "db_ingress_to_port" {
  type    = string
  default = 3306
}

variable "allocated_storage" {
  type = number
}

variable "storage_type" {
  type = string
}

variable "engine" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "db_name" {
  type = string
}



