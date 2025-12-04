variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "devops-assignment"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_ami" {
  description = "AMI id for EC2 instances (optional). If empty, the root module will lookup a recent Amazon Linux 2 AMI."
  type        = string
  default     = ""
}

variable "desired_capacity" {
  description = "ASG desired capacity"
  type        = number
  default     = 1
}

variable "min_size" {
  description = "ASG minimum size"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "ASG maximum size"
  type        = number
  default     = 2
}

variable "app_port" {
  description = "Port the app listens on"
  type        = number
  default     = 8080
}

variable "tags" {
  description = "Map of tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "key_name" {
  description = "Optional EC2 key pair name (leave empty to not set)"
  type        = string
  default     = ""
}