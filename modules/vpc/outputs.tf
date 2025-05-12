output "vpc_id" {
  value = aws_vpc.myvpc.id
}

output "public_subnet1" {
  value = aws_subnet.public_subnet1.id
}

output "public_subnet2" {
  value = aws_subnet.public_subnet2.id
}


output "private_subnet_id" {
  value = aws_subnet.private_subnet.id
}