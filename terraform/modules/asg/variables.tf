variable "instance_ami" { type = string }
variable "instance_type" { type = string }
variable "key_name" {
  type    = string
  default = ""
}
variable "user_data" { type = string }
variable "ec2_security_group" { type = string }
variable "alb_security_group" { type = string }
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "vpc_id" { type = string }
variable "app_port" { type = number }
variable "desired_capacity" { type = number }
variable "name_prefix" { type = string }
variable "min_size" {
  type    = number
  default = 1
}
variable "max_size" {
  type    = number
  default = 2
}
variable "tags" {
  type    = map(string)
  default = {}
}
