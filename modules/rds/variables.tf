variable "private_subnet_id" {
  description = "The ID of the private subnet"
  type        = string
}

variable "public_subnet_id1" {
  description = "The ID of the public subnet"
  type        = string
}

variable "rds_sg_id" {
  description = "The ID of the RDS security group"
  type        = string
}

variable "mysql_user" {
  description = "The MySQL username"
  type        = string
}

variable "mysql_password" {
  description = "The MySQL password"
  type        = string
}

variable "mysql_db" {
  description = "The MySQL database name"
  type        = string
}