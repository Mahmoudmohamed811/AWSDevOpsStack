variable "mysql_password" {
  default = "YUSSUFyasser"
}

variable "mysql_db" {
  default = "todos"
}

variable "mysql_user" {
  default = "root"
}

variable "access_key" {
  description = "AWS access key"
  type        = string
}

variable "secret_key" {
  description = "AWS secret key"
  type        = string
}

variable "session_token" {
  description = "AWS session token"
  type        = string
}
