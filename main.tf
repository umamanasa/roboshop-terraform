module "vpc" {
  source   = "git::https://github.com/umamanasa/tf-module-vpc.git"

  for_each        = var.cidr
  cidr            = each.value["cidr"]
  subnets         = each.value["subnets"]
}


