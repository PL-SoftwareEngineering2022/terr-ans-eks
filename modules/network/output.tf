output "private-subnet-ids" {
  value = aws_subnet.cali-private-subnet[*].id
}

output "public-subnet-ids" {
  value = aws_subnet.cali-pub-subnet[*].id
}
output "vpc_id" {
  value = aws_vpc.cali-vpc.id
}