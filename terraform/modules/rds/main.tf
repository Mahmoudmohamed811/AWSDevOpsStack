resource "aws_db_subnet_group" "myrds_subnet_group" {
  name       = "myrds-subnet-group"
  subnet_ids = [var.private_subnet_id, var.public_subnet_id1]

  tags = {
    Name = "My RDS Subnet Group"
  }
}

resource "aws_db_instance" "myrds" {
  identifier             = "myrds"
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  vpc_security_group_ids = [var.rds_sg_id]
  skip_final_snapshot    = true
  multi_az               = false
  availability_zone      = "us-east-1b"
  db_subnet_group_name   = aws_db_subnet_group.myrds_subnet_group.name
  username               = var.mysql_user
  password               = var.mysql_password
  parameter_group_name   = "default.mysql5.7"
}