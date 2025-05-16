output "web_instance_ip_0" {
  description = "First web instance IP"
  value       = module.ec2.web_instance_0_ip
}

output "web_instance_ip_1" {
  description = "Second web instance IP"
  value       = module.ec2.web_instance_1_ip
}

output "prometheus_instance" {
  description = "prometheus_instance instance IP"
  value       = module.ec2.prometheus_instance_ip
}

output "rds_address" {
  value = module.rds.rds_address
}