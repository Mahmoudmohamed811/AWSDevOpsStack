resource "aws_security_group" "rds-sg" {
  name        = "rds sg"
  description = "SG for RDS"
  vpc_id      = var.vpc_id
}

resource "aws_security_group" "web-sg" {
  name        = "web sg"
  description = "SG for Web Server"
  vpc_id      = var.vpc_id
}

resource "aws_security_group" "promtheus-sg" {
  name        = "promtheus sg"
  description = "SG for promtheus Server"
  vpc_id      = var.vpc_id
}

resource "aws_security_group" "alb-sg" {
  name        = "alb sg"
  description = "SG for aplication load balancer"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "web_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.web-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "web_inbound_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.web-sg.id
  source_security_group_id = aws_security_group.alb-sg.id
}

resource "aws_security_group_rule" "web_inbound_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.web-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.alb-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_inbound_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "promtheus_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.promtheus-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "promtheus_inbound_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.promtheus-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}




resource "aws_security_group_rule" "rds_from_web" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds-sg.id
  source_security_group_id = aws_security_group.web-sg.id
}
