<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_s3_bucket"></a> [s3\_bucket](#module\_s3\_bucket) | terraform-aws-modules/s3-bucket/aws | 2.13.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_s3_bucket"></a> [s3\_bucket](#input\_s3\_bucket) | AWS S3 bucket | <pre>object({<br>    name       = string<br>    kms_key_id = string<br>    tags       = object({})<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | KMS ARN of AWS S3 bucket |
| <a name="output_selected"></a> [selected](#output\_selected) | AWS S3 bucket |
<!-- END_TF_DOCS -->