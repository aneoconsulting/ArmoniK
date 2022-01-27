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
| [kubernetes_config_map.activemq_jetty_xml](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_deployment.activemq](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_service.activemq](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [local_file.activemq_jetty_xml_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_activemq"></a> [activemq](#input\_activemq) | Parameters of ActiveMQ | <pre>object({<br>    replicas = number<br>    port     = list(object({<br>      name        = string<br>      port        = number<br>      target_port = number<br>      protocol    = string<br>    }))<br>  })</pre> | n/a | yes |
| <a name="input_kubernetes_secret"></a> [kubernetes\_secret](#input\_kubernetes\_secret) | Secret for ActiveMQ created in Kubernetes | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK storage resources | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_deployment"></a> [deployment](#output\_deployment) | n/a |
| <a name="output_service"></a> [service](#output\_service) | ActiveMQ |
<!-- END_TF_DOCS -->