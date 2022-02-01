<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_external"></a> [external](#provider\_external) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |
| <a name="provider_local"></a> [local](#provider\_local) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_cluster_role.prometheus](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role) | resource |
| [kubernetes_cluster_role_binding.prometheus](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |
| [kubernetes_cluster_role_binding.prometheus_ns_armonik](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |
| [kubernetes_config_map.prometheus_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_daemonset.nodeexporter](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/daemonset) | resource |
| [kubernetes_deployment.prometheus](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_service.prometheus](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [local_file.prometheus_config_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [external_external.prometheus_node_ip](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_docker_image"></a> [docker\_image](#input\_docker\_image) | Docker image for Prometheus | <pre>object({<br>    image = string<br>    tag   = string<br>  })</pre> | <pre>{<br>  "image": "prom/prometheus",<br>  "tag": "latest"<br>}</pre> | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK monitoring | `string` | n/a | yes |
| <a name="input_prometheus"></a> [prometheus](#input\_prometheus) | Parameters of prometheus | <pre>object({<br>    replicas = number<br>    port     = object({<br>      name        = string<br>      port        = number<br>      target_port = number<br>      protocol    = string<br>    })<br>  })</pre> | <pre>{<br>  "port": {<br>    "name": "prometheus",<br>    "port": 9090,<br>    "protocol": "TCP",<br>    "target_port": 9090<br>  },<br>  "replicas": 1<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_prometheus"></a> [prometheus](#output\_prometheus) | prometheus |
| <a name="output_prometheus_url"></a> [prometheus\_url](#output\_prometheus\_url) | n/a |
<!-- END_TF_DOCS -->