variable "public_subnet_id1" {
  description = "The ID of the public subnet"
  type        = string
}

variable "public_subnet_id2" {
  description = "The ID of the public subnet"
  type        = string
}


variable "alb_sg_id" {
  description = "The ID of the ALB security group"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}


variable "web_instance_id_0" {
  description = "First web instance ID"
}


variable "web_instance_id_1" {
  description = "First web instance ID"
}
