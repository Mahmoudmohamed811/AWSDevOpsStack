resource "aws_instance" "web_instance_id_0" {
  ami                         = "ami-0e449927258d45bc4"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [var.web_sg_id]
  subnet_id                   = var.public_subnet_id1
  associate_public_ip_address = true
  key_name                    = "vockey"

  tags = {
    Name = "web0"
  }

  # user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
  #   MYSQL_PASSWORD = var.mysql_password,
  #   MYSQL_DB       = var.mysql_db,
  #   MYSQL_USER     = var.mysql_user,
  #   MYSQL_HOST     = var.mysql_host
  # })

  depends_on = [var.mysql_host]
}


resource "aws_instance" "web_instance_id_1" {
  ami                         = "ami-0e449927258d45bc4"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [var.web_sg_id]
  subnet_id                   = var.public_subnet_id2
  associate_public_ip_address = true
  key_name                    = "vockey"
  tags = {
    Name = "web1"
  }

  # user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
  #   MYSQL_PASSWORD = var.mysql_password,
  #   MYSQL_DB       = var.mysql_db,
  #   MYSQL_USER     = var.mysql_user,
  #   MYSQL_HOST     = var.mysql_host
  # })

  depends_on = [var.mysql_host]
}

resource "aws_instance" "prometheus_instance" {
  ami                         = "ami-0e449927258d45bc4"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [var.promtheus_sg_id]
  subnet_id                   = var.public_subnet_id3
  associate_public_ip_address = true
  key_name                    = "vockey"
  tags = {
    Name = "prometheus_instance"
  }
}

resource "aws_instance" "grafana_instance" {
  ami                         = "ami-0e449927258d45bc4"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [var.grafana_sg_id]
  subnet_id                   = var.public_subnet_id3
  associate_public_ip_address = true
  key_name                    = "vockey"
  tags = {
    Name = "grafana_instance"
  }
}