variable "name_prefix" { type = string }
variable "vpc_cidr" { type = string }
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "aws_region" { type = string }
variable "tags" { type = map(string) }
variable "app_port" {
  description = "Port the application listens on (used by EC2 SG)"
  type        = number
  default     = 8080
}