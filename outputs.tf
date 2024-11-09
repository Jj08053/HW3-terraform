output "instance1_public_ip" {
  description = "Public IP address of the public instance in east 1a"
  value       = aws_instance.public_instance_1.public_ip
}

output "instance2_public_ip" {
  description = "Public IP address of the public instance in east 1b"
  value       = aws_instance.public_instance_2.public_ip
}

output "rds_endpoint" {
  description = "Endpoint of the rds database"
  value       = aws_db_instance.rds_database.endpoint
}