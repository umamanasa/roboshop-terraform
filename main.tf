module "vpc" {
  source   = "git::https://github.com/umamanasa/tf-module-vpc.git"

  for_each                      = var.vpc
  cidr                          = each.value["cidr"]
  subnets                       = each.value["subnets"]
  default_vpc_id                = var.default_vpc_id
  default_vpc_cidr              = var.default_vpc_cidr
  default_vpc_route_table_id    = var.default_vpc_route_table_id
  tags                          = var.tags
  env                           = var.env
}

module "alb" {
  source   = "git::https://github.com/umamanasa/tf-module-alb.git"

  for_each                      = var.alb
  internal                      = each.value["internal"]
  lb_type                       = each.value["lb_type"]
  sg_ingress_cidr               = each.value["sg_ingress_cidr"]
  vpc_id                        = each.value["internal"] ? local.vpc_id : var.default_vpc_id
  subnets                       = each.value["internal"] ? local.app_subnets: data.aws_subnets.subnets.ids
  tags                          = var.tags
  env                           = var.env
  sg_port                       = each.value["sg_port"]
  acm_certificate_arn           = var.acm_certificate_arn
}

#module "docdb" {
#  source   = "git::https://github.com/umamanasa/tf-module-docdb.git"
#
#  tags                          = var.tags
#  env                           = var.env
#  for_each                      = var.docdb
#  subnet_ids                    = local.db_subnets
#  backup_retention_period       = each.value["backup_retention_period"]
#  preferred_backup_window       = each.value["preferred_backup_window"]
#  skip_final_snapshot           = each.value["skip_final_snapshot"]
#  vpc_id                        = local.vpc_id
#  sg_ingress_cidr               = local.app_subnets_cidr
#  engine_version                = each.value["engine_version"]
#  engine_family                 = each.value["engine_family"]
#  instance_count                = each.value["instance_count"]
#  instance_class                = each.value["instance_class"]
#  kms_key_id                     = var.kms_key_id             #comment this as i dont have encryption kms key
#}
#
#module "rds" {
#  source   = "git::https://github.com/umamanasa/tf-module-rds.git"
#
#  tags                          = var.tags
#  env                           = var.env
#
#  for_each                      = var.rds
#
#  subnet_ids                    = local.db_subnets
#  vpc_id                        = local.vpc_id
#  sg_ingress_cidr               = local.app_subnets_cidr
#  rds_type                      = each.value["rds_type"]
#  db_port                       = each.value["db_port"]
#  engine_family                 = each.value["engine_family"]
#  engine                        = each.value["engine"]
#  engine_version                = each.value["engine_version"]
#  backup_retention_period       = each.value["backup_retention_period"]
#  preferred_backup_window       = each.value["preferred_backup_window"]
#  skip_final_snapshot           = each.value["skip_final_snapshot"]
#  instance_count                = each.value["instance_count"]
#  instance_class                = each.value["instance_class"]
#  kms_key_id                    = var.kms_key_id             #comment this as i dont have encryption kms key
#
#}
#
#module "elasticache" {
#  source   = "git::https://github.com/umamanasa/tf-module-elasticache.git"
#
#  tags                          = var.tags
#  env                           = var.env
#
#  for_each                      = var.elasticache
#
#  subnet_ids                    = local.db_subnets
#  vpc_id                        = local.vpc_id
#  sg_ingress_cidr               = local.app_subnets_cidr
#  elasticache_type              = each.value["elasticache_type"]
#  family                        = each.value["family"]
#  port                          = each.value["port"]
#  engine                        = each.value["engine"]
#  node_type                     = each.value["node_type"]
#  num_cache_nodes               = each.value["num_cache_nodes"]
#  engine_version                = each.value["engine_version"]
#
#}
#
#module "rabbitmq" {
#  source   = "git::https://github.com/umamanasa/tf-module-rabbitmq.git"
#
#  tags                          = var.tags
#  env                           = var.env
#  zone_id                       = var.zone_id
#  for_each                      = var.rabbitmq
#
#  subnet_ids                    = local.db_subnets
#  vpc_id                        = local.vpc_id
#  sg_ingress_cidr               = local.app_subnets_cidr
#  instance_type                 = each.value["instance_type"]
#  ssh_ingress_cidr              = var.ssh_ingress_cidr
#  kms_key_id                    = var.kms_key_id             #comment this as i dont have encryption kms key
#}

module "app" {
#  depends_on = [module.docdb, module.alb, module.elasticache, module.rabbitmq, module.rds]
  source     = "git::https://github.com/umamanasa/tf-module-app.git"

  tags                          = merge(var.tags, each.value["tags"])
  env                           = var.env
  zone_id                       = var.zone_id
  ssh_ingress_cidr              = var.ssh_ingress_cidr
  default_vpc_id                = var.default_vpc_id
  monitoring_ingress_cidr       = var.monitoring_ingress_cidr
  az                            = var.az
#  kms_key_id                    = var.kms_key_id             #comment this as i dont have encryption kms key

  for_each                      = var.apps
  component                     = each.key
  port                          = each.value["port"]
  instance_type                 = each.value["instance_type"]
  desired_capacity              = each.value["desired_capacity"]
  max_size                      = each.value["max_size"]
  min_size                      = each.value["min_size"]
  lb_priority                   = each.value["lb_priority"]
  parameters                    = each.value["parameters"]

  sg_ingress_cidr               = local.app_subnets_cidr
  vpc_id                        = local.vpc_id
  subnet_ids                    = local.app_subnets

  private_alb_name              = lookup(lookup(lookup(module.alb, "private", null), "alb", null), "dns_name", null)
  public_alb_name              = lookup(lookup(lookup(module.alb, "public", null), "alb", null), "dns_name", null)
  private_listener              = lookup(lookup(lookup(module.alb, "private", null), "listener", null), "arn", null)
  public_listener              = lookup(lookup(lookup(module.alb, "public", null), "listener", null), "arn", null)
}

resource "aws_instance" "load_runner" {
  ami                       = data.aws_ami.ami.id
  vpc_security_group_ids    = ["sg-041096a23e28b0eb0"]
  instance_type             = "t3.medium"
  tags = {
    name = "load-runner"
  }
}

#For KUBERNETES Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "prod-roboshop"
  cluster_version = "1.28"

  cluster_endpoint_public_access  = false

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = local.vpc_id
  subnet_ids               = local.app_subnets
  control_plane_subnet_ids = local.app_subnets

    self_managed_node_groups = {
    one = {
      name         = "mixed-1"
      max_size     = 5
      desired_size = 2

      use_mixed_instances_policy = true
      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 0
          on_demand_percentage_above_base_capacity = 10
          spot_allocation_strategy                 = "capacity-optimized"
        }

        override = [
          {
            instance_type     = "t3.medium"
            weighted_capacity = "1"
          },
          {
            instance_type     = "t3.large"
            weighted_capacity = "2"
          },
        ]
      }
    }
  }

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  }

  eks_managed_node_groups = {
    blue = {}
    green = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
    }
  }

  # Fargate Profile(s)
  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = "default"
        }
      ]
    }
  }

  # aws-auth configmap
  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::66666666666:role/role1"
      username = "role1"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::66666666666:user/user1"
      username = "user1"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::66666666666:user/user2"
      username = "user2"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_accounts = [
    "777777777777",
    "888888888888",
  ]

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}