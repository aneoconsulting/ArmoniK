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
| [kubernetes_config_map.control_plane_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.polling_agent_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.worker_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_deployment.compute_plane](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_deployment.control_plane](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_service.control_plane](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [local_file.control_plane_config_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.polling_agent_config_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.worker_config_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [external_external.control_plane_node_ip](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_compute_plane"></a> [compute\_plane](#input\_compute\_plane) | Parameters of the compute plane | <pre>object({<br>    replicas                         = number<br>    termination_grace_period_seconds = number<br>    # number of queues according to priority of tasks<br>    max_priority                     = number<br>    image_pull_secrets               = string<br>    polling_agent                    = object({<br>      image             = string<br>      tag               = string<br>      image_pull_policy = string<br>      limits            = object({<br>        cpu    = string<br>        memory = string<br>      })<br>      requests          = object({<br>        cpu    = string<br>        memory = string<br>      })<br>    })<br>    worker                           = list(object({<br>      name              = string<br>      port              = number<br>      image             = string<br>      tag               = string<br>      image_pull_policy = string<br>      limits            = object({<br>        cpu    = string<br>        memory = string<br>      })<br>      requests          = object({<br>        cpu    = string<br>        memory = string<br>      })<br>    }))<br>  })</pre> | n/a | yes |
| <a name="input_control_plane"></a> [control\_plane](#input\_control\_plane) | Parameters of the control plane | <pre>object({<br>    replicas           = number<br>    image              = string<br>    tag                = string<br>    image_pull_policy  = string<br>    port               = number<br>    limits             = object({<br>      cpu    = string<br>      memory = string<br>    })<br>    requests           = object({<br>      cpu    = string<br>      memory = string<br>    })<br>    image_pull_secrets = string<br>  })</pre> | n/a | yes |
| <a name="input_logging_level"></a> [logging\_level](#input\_logging\_level) | Logging level in ArmoniK | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK resources | `string` | n/a | yes |
| <a name="input_seq_endpoints"></a> [seq\_endpoints](#input\_seq\_endpoints) | Endpoint URL of Seq | <pre>object({<br>    url  = string<br>    host = string<br>    port = string<br>  })</pre> | n/a | yes |
| <a name="input_storage"></a> [storage](#input\_storage) | List of storage needed by ArmoniK | <pre>object({<br>    data_type = object({<br>      object         = string<br>      table          = string<br>      queue          = string<br>      lease_provider = string<br>      shared         = string<br>      external       = string<br>    })<br>    list      = list(string)<br>  })</pre> | n/a | yes |
| <a name="input_storage_adapters"></a> [storage\_adapters](#input\_storage\_adapters) | ArmoniK storage adapters | <pre>object({<br>    object         = string<br>    table          = string<br>    queue          = string<br>    lease_provider = string<br>  })</pre> | n/a | yes |
| <a name="input_storage_endpoint_url"></a> [storage\_endpoint\_url](#input\_storage\_endpoint\_url) | Endpoints and secrets of storage resources | <pre>object({<br>    mongodb  = object({<br>      host   = string<br>      port   = string<br>      secret = string<br>    })<br>    redis    = object({<br>      url    = string<br>      secret = string<br>    })<br>    activemq = object({<br>      host   = string<br>      port   = string<br>      secret = string<br>    })<br>    shared   = object({<br>      host   = string<br>      id     = string<br>      secret = string<br>      path   = string<br>    })<br>    external = object({<br>      url    = string<br>      secret = string<br>    })<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_compute_plane"></a> [compute\_plane](#output\_compute\_plane) | Armonik compute plane |
| <a name="output_control_plane"></a> [control\_plane](#output\_control\_plane) | Armonik control plane |
| <a name="output_control_plane_url"></a> [control\_plane\_url](#output\_control\_plane\_url) | n/a |
<!-- END_TF_DOCS -->