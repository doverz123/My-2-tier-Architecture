output "PublicIP" {
  description = "Public IP of EC2 instance"
  value       = aws_instance.httpd-web-server-1.public_ip
}
output "PublicIP2" {
  description = "Public IP of EC2 instance"
  value       = aws_instance.httpd-web-server-2.public_ip
}

output "ALB_DNS" {
  description = "The ALBs DNS"
  value       = aws_lb.ALB.dns_name
}