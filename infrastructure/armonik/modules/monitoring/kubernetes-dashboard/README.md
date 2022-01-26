<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_cluster_role.kubernetes_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role) | resource |
| [kubernetes_cluster_role_binding.kubernetes_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |
| [kubernetes_config_map.kubernetes_dashboard_settings](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_deployment.dashboard_metrics_scraper](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_deployment.kubernetes_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_role.kubernetes_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role) | resource |
| [kubernetes_role_binding.admin_user](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding) | resource |
| [kubernetes_role_binding.kubernetes_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding) | resource |
| [kubernetes_secret.kubernetes_dashboard_certs](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.kubernetes_dashboard_csrf](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.kubernetes_dashboard_key_holder](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_service.dashboard_metrics_scraper](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [kubernetes_service.kubernetes_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [kubernetes_service_account.admin_user](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [kubernetes_service_account.kubernetes_dashboard](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [kubernetes_service_account.kubernetes_dashboard_service_account](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service_account) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dashboard_metrics_scraper"></a> [dashboard\_metrics\_scraper](#input\_dashboard\_metrics\_scraper) | Parameters of dashboard metrics scraper | <pre>object({<br>    replicas = number<br>    port     = object({<br>      name        = string<br>      port        = number<br>      target_port = number<br>      protocol    = string<br>    })<br>  })</pre> | <pre>{<br>  "port": {<br>    "name": "scraper",<br>    "port": 8000,<br>    "protocol": "TCP",<br>    "target_port": 8000<br>  },<br>  "replicas": 1<br>}</pre> | no |
| <a name="input_kubernetes_dashboard"></a> [kubernetes\_dashboard](#input\_kubernetes\_dashboard) | Parameters of Kubernetes dashboard | <pre>object({<br>    replicas = number<br>    port     = object({<br>      name        = string<br>      port        = number<br>      target_port = number<br>      protocol    = string<br>    })<br>  })</pre> | <pre>{<br>  "port": {<br>    "name": "dashboard",<br>    "port": 443,<br>    "protocol": "TCP",<br>    "target_port": 8443<br>  },<br>  "replicas": 1<br>}</pre> | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK monitoring | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kubernetes_dashboard_url"></a> [kubernetes\_dashboard\_url](#output\_kubernetes\_dashboard\_url) | n/a |
<!-- END_TF_DOCS -->