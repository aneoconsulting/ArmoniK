<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.7.1 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.7.1 |
| <a name="provider_local"></a> [local](#provider\_local) | >= 2.1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_config_map.init_mongodb_js](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_deployment.mongodb](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_service.mongodb](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [local_file.init_mongodb_js_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_kubernetes_secret"></a> [kubernetes\_secret](#input\_kubernetes\_secret) | Secret for MongoDB created in Kubernetes | `string` | n/a | yes |
| <a name="input_mongodb"></a> [mongodb](#input\_mongodb) | Parameters of MongoDB | <pre>object({<br>    replicas = number<br>    port     = number<br>  })</pre> | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK storage resources | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_deployment"></a> [deployment](#output\_deployment) | n/a |
| <a name="output_service"></a> [service](#output\_service) | MongoDB |
<!-- END_TF_DOCS -->