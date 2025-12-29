data "aws_availability_zones" "available" {
  region = var.region
}

locals {
  azs        = slice(data.aws_availability_zones.available.names, 0, 3)
  db_subnets = var.create_database_subnets ? var.database_subnets : []
}
