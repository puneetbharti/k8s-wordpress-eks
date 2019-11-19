module "sre-challenge-cluster" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = var.k8s_cluster_name
  subnets      = module.app_vpc.private_subnets
  vpc_id       = module.app_vpc.vpc_id

  worker_groups = [
    {
      instance_type = "t2.micro"
      asg_desired_capacity = 5
      asg_min_size  = 5
      asg_max_size  = 12
      tags = [{
        key                 = "Name"
        value               = "sre-challenge-worker"
        propagate_at_launch = true
      }]
    }
  ]

  tags = {
    environment = "prod"
  }
}
