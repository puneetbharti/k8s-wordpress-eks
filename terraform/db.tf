module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 2.0"

  identifier = "srechallengedb"

  engine            = "mysql"
  engine_version    = "5.7.19"
  instance_class    = "db.t2.large"
  allocated_storage = 5

  name     = "srechallengedb"
  username = "root"
  password = "j&-$q!T?RF5L5Xmv"
  port     = "3306"

  iam_database_authentication_enabled = true

  vpc_security_group_ids = ["${module.db_vpc.default_security_group_id}", "${aws_security_group.allow_apps.id}"]
  multi_az = "true"

  
  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
  backup_retention_period = "35"

  # Enhanced Monitoring - see example for details on how to create the role
  # by yourself, in case you don't want to create it automatically
  # monitoring_interval = "30"
  monitoring_role_name = "MyRDSMonitoringRole"
  create_monitoring_role = true

  tags = {
    Owner       = "root"
    Environment = "prod"
  }

  # DB subnet group
  subnet_ids = module.db_vpc.private_subnets

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  create_db_option_group = "false"
  major_engine_version = "5.7"

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "srechallengedb"

  # Database Deletion Protection
  deletion_protection = true

  parameters = [
    {
      name = "character_set_client"
      value = "utf8"
    },
    {
      name = "character_set_server"
      value = "utf8"
    }
  ]

}

resource "aws_security_group" "allow_apps" {
  name        = "allow_apps"
  description = "Allow apps inbound traffic"
  vpc_id        = "${module.db_vpc.vpc_id}"

 
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    cidr_blocks     = ["${var.app_cidr}"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
