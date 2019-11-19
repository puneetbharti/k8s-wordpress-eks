resource "aws_efs_file_system" "sre-challenge-efs" {
  creation_token = "sre-challenge-efs"

  tags = {
    Name = "sre-challenge-efs"
  }
}

resource "aws_efs_mount_target" "sre-challenge-efs" {
  count = length("${module.app_vpc.private_subnets}")
  file_system_id = "${aws_efs_file_system.sre-challenge-efs.id}"
  subnet_id      = "${module.app_vpc.private_subnets[count.index]}"
  security_groups = ["${aws_security_group.allow_efs_mounts.id}"]
}

resource "aws_security_group" "allow_efs_mounts" {
  name        = "allow_efs_mount"
  description = "Allow EFS inbound traffic"
  vpc_id        = "${module.app_vpc.vpc_id}"

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    self = true
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["${var.app_cidr}"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

