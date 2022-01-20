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

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_kms_alias.kms_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_iam_policy_document.kms_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Account ID that will have permissions. | `string` | n/a | yes |
| <a name="input_kms"></a> [kms](#input\_kms) | AWS Key Management Service parameters | <pre>object({<br>    name                     = string<br>    multi_region             = bool<br>    deletion_window_in_days  = number<br>    customer_master_key_spec = string<br>    key_usage                = string<br>    enable_key_rotation      = bool<br>    is_enabled               = bool<br>  })</pre> | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region where the infrastructure will be deployed | `string` | n/a | yes |
| <a name="input_tag"></a> [tag](#input\_tag) | Tag to prefix the AWS resources | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kms"></a> [kms](#output\_kms) | KMS |
<!-- END_TF_DOCS -->