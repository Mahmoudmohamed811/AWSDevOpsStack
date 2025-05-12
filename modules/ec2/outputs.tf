output "web_instance_id_0" {
  description = "First web instance ID"
  value       = aws_instance.web_instance_id_0.id
}

output "web_instance_0_ip" {
  description = "First web instance IP"
  value       = aws_instance.web_instance_id_0.public_ip
}

output "web_instance_id_1" {
  description = "Second web instance ID"
  value       = aws_instance.web_instance_id_1.id
}

output "web_instance_1_ip" {
  description = "Second web instance IP"
  value       = aws_instance.web_instance_id_1.public_ip
}
