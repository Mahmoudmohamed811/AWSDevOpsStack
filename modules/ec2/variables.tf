variable "public_subnet_id1" {
  description = "The ID of the public subnet"
  type        = string
}

variable "public_subnet_id2" {
  description = "The ID of the public subnet"
  type        = string
}

variable "web_sg_id" {
  description = "The ID of the web security group"
  type        = string
}

# variable "mysql_user" {
#   description = "The MySQL username"
#   type        = string
# }

# variable "mysql_password" {
#   description = "The MySQL password"
#   type        = string
# }

# variable "mysql_db" {
#   description = "The MySQL database name"
#   type        = string
# }

variable "mysql_host" {
  description = "The MySQL host address"
  type        = string
}