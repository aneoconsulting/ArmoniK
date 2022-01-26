<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_kms"></a> [kms](#module\_kms) | ../../../../modules/aws/kms | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ebs_volume.shared_ebs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [random_string.random_resources](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ebs"></a> [ebs](#input\_ebs) | AWS EBS for shared storage between pods | <pre>object({<br>    availability_zone = string<br>    size              = number<br>    encrypted         = bool<br>    kms_key_id        = string<br>    tags              = object({})<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_selected"></a> [selected](#output\_selected) | AWS Elastic Block Store object |
<!-- END_TF_DOCS -->