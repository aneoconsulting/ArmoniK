# VPC
vpc_parameters = {
  name                                            = "armonik-vpc"
  cidr                                            = "10.0.0.0/16"
  private_subnets_cidr                            = ["10.0.0.0/18", "10.0.64.0/18", "10.0.128.0/18"]
  public_subnets_cidr                             = ["10.0.192.0/24", "10.0.193.0/24", "10.0.194.0/24"]
  enable_private_subnet                           = true
  flow_log_cloudwatch_log_group_kms_key_id        = ""
  flow_log_cloudwatch_log_group_retention_in_days = 30
}



