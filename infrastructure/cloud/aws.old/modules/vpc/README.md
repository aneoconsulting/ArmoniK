<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.72.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.72.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 3.11.3 |

## Resources

| Name | Type |
|------|------|
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account"></a> [account](#input\_account) | Account ID that will have permissions. | `any` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Kubernetes cluster name | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region where the infrastructure will be deployed | `string` | n/a | yes |
| <a name="input_tag"></a> [tag](#input\_tag) | Tag to prefix the AWS resources | `string` | n/a | yes |
| <a name="input_vpc"></a> [vpc](#input\_vpc) | Parameters of AWS VPC | <pre>object({<br>    name                  = string<br>    cidr                  = string<br>    private_subnets_cidr  = list(string)<br>    public_subnets_cidr   = list(string)<br>    enable_private_subnet = bool<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_selected"></a> [selected](#output\_selected) | n/a |
<!-- END_TF_DOCS -->