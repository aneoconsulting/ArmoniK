<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

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
| <a name="input_kms"></a> [kms](#input\_kms) | AWS Key Management Service parameters | <pre>object({<br>    name                     = string<br>    region                   = string<br>    account_id               = string<br>    multi_region             = bool<br>    deletion_window_in_days  = number<br>    customer_master_key_spec = string<br>    key_usage                = string<br>    enable_key_rotation      = bool<br>    is_enabled               = bool<br>    tags                     = map(string)<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kms_alias"></a> [kms\_alias](#output\_kms\_alias) | n/a |
| <a name="output_selected"></a> [selected](#output\_selected) | n/a |
<!-- END_TF_DOCS -->