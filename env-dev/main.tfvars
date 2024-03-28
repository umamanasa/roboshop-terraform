default_vpc_id              = "vpc-027d9d74cfa8ed833"
default_vpc_cidr            = "172.31.0.0/16"
default_vpc_route_table_id  = "rtb-0c2ca2a512e7fa3d7"
zone_id                     = "Z0365188L7MG2LV8YN4J"
env                         = "dev"
ssh_ingress_cidr            = ["172.31.95.128/32"]        #workstation bastion node private IP
monitoring_ingress_cidr     = ["172.31.80.242/32"]         #Prometheus instance Private IP
acm_certificate_arn         = "arn:aws:acm:us-east-1:206243364202:certificate/82b4e2d0-0cba-40da-9ef0-367058ab2b36"  #ACM Certificate arn
#kms_key_id                  = ""                               #Kms Key encryption arn


tags = {
  company_name    = "ABC Tech"
  business_unit  = "Ecommerce"
  project_name    = "robotshop"
  cost_center     = "ecom_rs"
  created_by      = "terraform"
}

az = ["us-east-1a", "us-east-1b"]

vpc = {
  main = {
    cidr = "10.0.0.0/16"
    subnets = {
      public = {
        public1 = { cidr = "10.0.0.0/24", az = "us-east-1a" }
        public2 = { cidr = "10.0.1.0/24", az = "us-east-1b" }
      }
      app = {
        app1 = { cidr = "10.0.2.0/24", az = "us-east-1a" }
        app2 = { cidr = "10.0.3.0/24", az = "us-east-1b" }
      }
      db = {
        db1 = { cidr = "10.0.4.0/24", az = "us-east-1a" }
        db2 = { cidr = "10.0.5.0/24", az = "us-east-1b" }
      }
    }
  }
}

alb = {
  public = {
    internal          = false
    lb_type           = "application"
    sg_ingress_cidr   = ["0.0.0.0/0"]
    sg_port           = 443
  }
  private = {
    internal          = true
    lb_type           = "application"
    sg_ingress_cidr   = ["172.31.0.0/16", "10.0.0.0/16"]
    sg_port           = 80
  }
}

docdb = {
  main = {
    backup_retention_period = 5
    preferred_backup_window = "07:00-09:00"
    skip_final_snapshot     = true
    engine_version          = "4.0.0"
    engine_family           = "docdb4.0"
    instance_count          = 1
    instance_class          = "db.t3.medium"
  }
}

rds = {
  main = {
    rds_type                      = "mysql"
    db_port                       = 3306
    engine_family                 = "aurora-mysql5.7"
    engine                        = "aurora-mysql"
    engine_version                = "5.7.mysql_aurora.2.11.3"
    backup_retention_period       = 5
    preferred_backup_window       = "07:00-09:00"
    skip_final_snapshot           = true
    instance_count                = 1
    instance_class                = "db.t3.small"
  }
}

elasticache = {
  main = {
    elasticache_type              = "redis"
    family                        = "redis6.x"
    port                          = 6379
    engine                        = "redis"
    node_type                     = "cache.t3.micro"
    num_cache_nodes               = 1
    engine_version                = "6.2"
  }
}

rabbitmq = {
  main = {
    instance_type    = "t3.small"
  }
}

apps = {
  frontend = {
    instance_type     = "t3.micro"
    port              = 80
    desired_capacity  = 1
    max_size          = 3
    min_size          = 1
    lb_priority       = 1
    lb_type           = "public"
    parameters        = ["nexus"]
    tags              = { Monitor_Nginx = "yes" }
  }
  catalogue = {
    instance_type     = "t3.micro"
    port              = 8080
    desired_capacity  = 1
    max_size          = 3
    min_size          = 1
    lb_priority       = 2
    lb_type           = "private"
    parameters        = ["docdb", "nexus"]
    tags              = {}
  }
  user = {
    instance_type     = "t3.micro"
    port              = 8080
    desired_capacity  = 1
    max_size          = 3
    min_size          = 1
    lb_priority       = 3
    lb_type           = "private"
    parameters        = ["docdb", "nexus"]
    tags              = {}
  }
  cart = {
    instance_type     = "t3.micro"
    port              = 8080
    desired_capacity  = 1
    max_size          = 3
    min_size          = 1
    lb_priority       = 4
    lb_type           = "private"
    parameters        = ["nexus"]
    tags              = {}
  }
  payment = {
    instance_type     = "t3.micro"
    port              = 8080
    desired_capacity  = 1
    max_size          = 3
    min_size          = 1
    lb_priority       = 5
    lb_type           = "private"
    parameters        = ["rabbitmq", "nexus"]
    tags              = {}
  }
  shipping = {
    instance_type     = "t3.micro"
    port              = 8080
    desired_capacity  = 1
    max_size          = 3
    min_size          = 1
    lb_priority       = 6
    lb_type           = "private"
    parameters        = ["rds", "nexus"]
    tags              = {}
  }
}