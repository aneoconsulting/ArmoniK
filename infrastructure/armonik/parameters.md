<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_external"></a> [external](#requirement\_external) | >= 2.1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.7.1 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_external"></a> [external](#provider\_external) | >= 2.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_armonik"></a> [armonik](#module\_armonik) | ./modules/armonik-components | n/a |
| <a name="module_grafana"></a> [grafana](#module\_grafana) | ./modules/monitoring/grafana | n/a |
| <a name="module_prometheus"></a> [prometheus](#module\_prometheus) | ./modules/monitoring/prometheus | n/a |
| <a name="module_seq"></a> [seq](#module\_seq) | ./modules/monitoring/seq | n/a |
| <a name="module_storage"></a> [storage](#module\_storage) | ../modules/needed-storage | n/a |

## Resources

| Name | Type |
|------|------|
| [external_external.k8s_config_context](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_compute_plane"></a> [compute\_plane](#input\_compute\_plane) | Parameters of the compute plane | <pre>object({<br>    replicas                         = number<br>    termination_grace_period_seconds = number<br>    # number of queues according to priority of tasks<br>    max_priority                     = number<br>    image_pull_secrets               = string<br>    polling_agent                    = object({<br>      image             = string<br>      tag               = string<br>      image_pull_policy = string<br>      limits            = object({<br>        cpu    = string<br>        memory = string<br>      })<br>      requests          = object({<br>        cpu    = string<br>        memory = string<br>      })<br>    })<br>    worker                           = list(object({<br>      name              = string<br>      port              = number<br>      image             = string<br>      tag               = string<br>      image_pull_policy = string<br>      limits            = object({<br>        cpu    = string<br>        memory = string<br>      })<br>      requests          = object({<br>        cpu    = string<br>        memory = string<br>      })<br>    }))<br>  })</pre> | <pre>{<br>  "image_pull_secrets": "",<br>  "max_priority": 1,<br>  "polling_agent": {<br>    "image": "dockerhubaneo/armonik_pollingagent",<br>    "image_pull_policy": "IfNotPresent",<br>    "limits": {<br>      "cpu": "100m",<br>      "memory": "128Mi"<br>    },<br>    "requests": {<br>      "cpu": "100m",<br>      "memory": "128Mi"<br>    },<br>    "tag": "0.0.4"<br>  },<br>  "replicas": 1,<br>  "termination_grace_period_seconds": 30,<br>  "worker": [<br>    {<br>      "image": "dockerhubaneo/armonik_worker_dll",<br>      "image_pull_policy": "IfNotPresent",<br>      "limits": {<br>        "cpu": "920m",<br>        "memory": "2048Mi"<br>      },<br>      "name": "compute",<br>      "port": 80,<br>      "requests": {<br>        "cpu": "50m",<br>        "memory": "100Mi"<br>      },<br>      "tag": "0.0.4"<br>    }<br>  ]<br>}</pre> | no |
| <a name="input_control_plane"></a> [control\_plane](#input\_control\_plane) | Parameters of the control plane | <pre>object({<br>    replicas           = number<br>    image              = string<br>    tag                = string<br>    image_pull_policy  = string<br>    port               = number<br>    limits             = object({<br>      cpu    = string<br>      memory = string<br>    })<br>    requests           = object({<br>      cpu    = string<br>      memory = string<br>    })<br>    image_pull_secrets = string<br>  })</pre> | <pre>{<br>  "image": "dockerhubaneo/armonik_control",<br>  "image_pull_policy": "IfNotPresent",<br>  "image_pull_secrets": "",<br>  "limits": {<br>    "cpu": "1000m",<br>    "memory": "1024Mi"<br>  },<br>  "port": 5001,<br>  "replicas": 1,<br>  "requests": {<br>    "cpu": "100m",<br>    "memory": "128Mi"<br>  },<br>  "tag": "0.0.4"<br>}</pre> | no |
| <a name="input_k8s_config_context"></a> [k8s\_config\_context](#input\_k8s\_config\_context) | Context of K8s | `string` | `"default"` | no |
| <a name="input_k8s_config_path"></a> [k8s\_config\_path](#input\_k8s\_config\_path) | Path of the configuration file of K8s | `string` | `"~/.kube/config"` | no |
| <a name="input_logging_level"></a> [logging\_level](#input\_logging\_level) | Logging level | `string` | `"Information"` | no |
| <a name="input_monitoring"></a> [monitoring](#input\_monitoring) | Use monitoring tools | <pre>object({<br>    namespace  = string<br>    seq        = object({<br>      image = string<br>      tag   = string<br>      use   = bool<br>    })<br>    grafana    = object({<br>      image = string<br>      tag   = string<br>      use   = bool<br>    })<br>    prometheus = object({<br>      image = string<br>      tag   = string<br>      use   = bool<br>    })<br>  })</pre> | <pre>{<br>  "grafana": {<br>    "image": "grafana/grafana",<br>    "tag": "latest",<br>    "use": false<br>  },<br>  "namespace": "armonik-monitoring",<br>  "prometheus": {<br>    "image": "prom/prometheus",<br>    "tag": "latest",<br>    "use": false<br>  },<br>  "seq": {<br>    "image": "datalust/seq",<br>    "tag": "2021.4",<br>    "use": true<br>  }<br>}</pre> | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK resources | `string` | `"armonik"` | no |
| <a name="input_storage"></a> [storage](#input\_storage) | Needed storage for each ArmoniK data type | <pre>object({<br>    object         = string<br>    table          = string<br>    queue          = string<br>    lease_provider = string<br>    shared         = string<br>    external       = string<br>  })</pre> | <pre>{<br>  "external": "",<br>  "lease_provider": "MongoDB",<br>  "object": "Redis",<br>  "queue": "Amqp",<br>  "shared": "HostPath",<br>  "table": "MongoDB"<br>}</pre> | no |
| <a name="input_storage_endpoint_url"></a> [storage\_endpoint\_url](#input\_storage\_endpoint\_url) | Endpoints and secrets of storage resources | <pre>object({<br>    mongodb  = object({<br>      host   = string<br>      port   = string<br>      secret = string<br>    })<br>    redis    = object({<br>      url    = string<br>      secret = string<br>    })<br>    activemq = object({<br>      host   = string<br>      port   = string<br>      secret = string<br>    })<br>    shared   = object({<br>      host   = string<br>      secret = string<br>      id     = string<br>      path   = string<br>    })<br>    external = object({<br>      url    = string<br>      secret = string<br>    })<br>  })</pre> | <pre>{<br>  "activemq": {<br>    "host": "",<br>    "port": "",<br>    "secret": ""<br>  },<br>  "external": {<br>    "secret": "",<br>    "url": ""<br>  },<br>  "mongodb": {<br>    "host": "",<br>    "port": "",<br>    "secret": ""<br>  },<br>  "redis": {<br>    "secret": "",<br>    "url": ""<br>  },<br>  "shared": {<br>    "host": "",<br>    "id": "",<br>    "path": "/data",<br>    "secret": ""<br>  }<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_armonik_control_plane"></a> [armonik\_control\_plane](#output\_armonik\_control\_plane) | URL of ArmoniK control plane |
| <a name="output_armonik_grafana"></a> [armonik\_grafana](#output\_armonik\_grafana) | URL of Grafana |
| <a name="output_armonik_seq"></a> [armonik\_seq](#output\_armonik\_seq) | URL of Seq |
<!-- END_TF_DOCS -->