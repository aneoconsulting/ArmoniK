<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.72.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider\_random) | 3.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_account"></a> [account](#module\_account) | ./modules/account | n/a |
| <a name="module_kms"></a> [kms](#module\_kms) | ./modules/kms | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ./modules/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [random_string.random_resources](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_kms"></a> [kms](#input\_kms) | AWS Key Management Service parameters | <pre>object({<br>    name                     = string<br>    multi_region             = bool<br>    deletion_window_in_days  = number<br>    customer_master_key_spec = string<br>    key_usage                = string<br>    enable_key_rotation      = bool<br>    is_enabled               = bool<br>  })</pre> | n/a | yes |
| <a name="input_profile"></a> [profile](#input\_profile) | Profile of AWS credentials to deploy Terraform sources | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region where the infrastructure will be deployed | `string` | n/a | yes |
| <a name="input_tag"></a> [tag](#input\_tag) | Tag to prefix the AWS resources | `string` | n/a | yes |
| <a name="input_vpc"></a> [vpc](#input\_vpc) | Parameters of AWS VPC | <pre>object({<br>    name                  = string<br>    cidr                  = string<br>    private_subnets_cidr  = list(string)<br>    public_subnets_cidr   = list(string)<br>    enable_private_subnet = bool<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kms_arn"></a> [kms\_arn](#output\_kms\_arn) | KMS |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC |
<!-- END_TF_DOCS -->