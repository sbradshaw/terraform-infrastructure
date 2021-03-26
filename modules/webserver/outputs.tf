# modules/webserver/outputs.tf

output "instance" {
  value = aws_instance.app-server
}