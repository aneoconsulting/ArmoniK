<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 3.11.1 |
| <a name="module_vpc_endpoints"></a> [vpc\_endpoints](#module\_vpc\_endpoints) | terraform-aws-modules/vpc/aws//modules/vpc-endpoints | 3.11.1 |

## Resources

| Name | Type |
|------|------|
| [aws_security_group_rule.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_vpc"></a> [vpc](#input\_vpc) | Parameters of AWS VPC | <pre>object({<br>    cluster_name                                    = string<br>    main_cidr_block                                 = string<br>    pod_cidr_block_private                          = list(string)<br>    private_subnets                                 = list(string)<br>    public_subnets                                  = list(string)<br>    enable_private_subnet                           = bool<br>    enable_nat_gateway                              = bool<br>    single_nat_gateway                              = bool<br>    flow_log_cloudwatch_log_group_kms_key_id        = string<br>    flow_log_cloudwatch_log_group_retention_in_days = number<br>    tags                                            = map(string)<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_pods_subnet_ids"></a> [pods\_subnet\_ids](#output\_pods\_subnet\_ids) | ids of the private subnet created |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | ids of the private subnet created |
| <a name="output_selected"></a> [selected](#output\_selected) | Created VPC |
<!-- END_TF_DOCS -->