variable "availability_zones" {
  description = "AZ to use"
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "app_cidr" {
  description = "CIDR to use for the VPC"
  default     = "10.0.0.0/16"
}

variable "db_cidr" {
  description = "CIDR to use for the VPC"
  default     = "11.0.0.0/16"
}

variable "app_private_subnets_cidr" {
  description = "CIDR used for private subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "app_public_subnets_cidr" {
  description = "CIDR used for private subnets"
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "db_private_subnets_cidr" {
  description = "CIDR used for private subnets"
  default     = ["11.0.1.0/24", "11.0.2.0/24", "11.0.3.0/24"]
}

variable "db_public_subnets_cidr" {
  description = "CIDR used for private subnets"
  default     = ["11.0.101.0/24", "11.0.102.0/24", "11.0.103.0/24"]
}


variable "k8s_cluster_name" {
  default = "sre-challenge-cluster"
}

variable "repository_name" {
  default = "sre-challenge"
}
