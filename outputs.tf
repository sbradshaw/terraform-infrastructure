# outputs.tf

output "ec2_public_ip" {
  value = module.app-webserver.instance.public_ip
}
