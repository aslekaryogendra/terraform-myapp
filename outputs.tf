output "http_server_public_dns" {
    value = aws_instance.myinstance.public_dns
  
}