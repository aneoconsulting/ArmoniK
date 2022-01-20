<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_account"></a> [account](#module\_account) | ./modules/account | n/a |
| <a name="module_kms"></a> [kms](#module\_kms) | ./modules/kms | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_kms"></a> [kms](#input\_kms) | AWS Key Management Service parameters | <pre>object({<br>    name                     = string<br>    multi_region             = bool<br>    deletion_window_in_days  = number<br>    customer_master_key_spec = string<br>    key_usage                = string<br>    enable_key_rotation      = bool<br>    is_enabled               = bool<br>  })</pre> | <pre>{<br>  "customer_master_key_spec": "SYMMETRIC_DEFAULT",<br>  "deletion_window_in_days": 7,<br>  "enable_key_rotation": true,<br>  "is_enabled": true,<br>  "key_usage": "ENCRYPT_DECRYPT",<br>  "multi_region": false,<br>  "name": "armonik-kms"<br>}</pre> | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region where the infrastructure will be deployed | `string` | `"eu-west-3"` | no |
| <a name="input_tag"></a> [tag](#input\_tag) | Tag to prefix the AWS resources | `string` | `"main"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->