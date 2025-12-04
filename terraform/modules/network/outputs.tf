output "vpc_id" { value = aws_vpc.this.id }
output "public_subnets" { value = [for s in aws_subnet.public : s.id] }
output "private_subnets" { value = [for s in aws_subnet.private : s.id] }
output "alb_security_group" { value = aws_security_group.alb.id }
output "ec2_security_group" { value = aws_security_group.ec2.id }