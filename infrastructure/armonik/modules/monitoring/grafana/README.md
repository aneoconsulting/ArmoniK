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
| [kubernetes_config_map.dashboards_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.dashboards_json_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.datasources_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_deployment.grafana](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_service.grafana](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [local_file.dashboards_config_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.datasources_config_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [external_external.grafana_node_ip](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_docker_image"></a> [docker\_image](#input\_docker\_image) | Docker image for Grafana | <pre>object({<br>    image = string<br>    tag   = string<br>  })</pre> | <pre>{<br>  "image": "grafana/grafana",<br>  "tag": "latest"<br>}</pre> | no |
| <a name="input_grafana"></a> [grafana](#input\_grafana) | Parameters of Grafana | <pre>object({<br>    replicas = number<br>    port     = object({<br>      name        = string<br>      port        = number<br>      target_port = number<br>      protocol    = string<br>    })<br>  })</pre> | <pre>{<br>  "port": {<br>    "name": "grafana",<br>    "port": 3000,<br>    "protocol": "TCP",<br>    "target_port": 3000<br>  },<br>  "replicas": 1<br>}</pre> | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK monitoring | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_grafana"></a> [grafana](#output\_grafana) | Grafana |
| <a name="output_grafana_url"></a> [grafana\_url](#output\_grafana\_url) | n/a |
<!-- END_TF_DOCS -->