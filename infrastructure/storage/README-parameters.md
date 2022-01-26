<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.72.0 |
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
| <a name="module_activemq"></a> [activemq](#module\_activemq) | ./modules/onpremise/activemq | n/a |
| <a name="module_aws_ebs"></a> [aws\_ebs](#module\_aws\_ebs) | ./modules/aws/ebs | n/a |
| <a name="module_mongodb"></a> [mongodb](#module\_mongodb) | ./modules/onpremise/mongodb | n/a |
| <a name="module_redis"></a> [redis](#module\_redis) | ./modules/onpremise/redis | n/a |
| <a name="module_storage"></a> [storage](#module\_storage) | ../modules/needed-storage | n/a |

## Resources

| Name | Type |
|------|------|
| [external_external.activemq_node_ip](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [external_external.k8s_config_context](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [external_external.mongodb_node_ip](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [external_external.redis_node_ip](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_activemq"></a> [activemq](#input\_activemq) | Parameters of ActiveMQ | <pre>object({<br>    replicas = number<br>    port     = list(object({<br>      name        = string<br>      port        = number<br>      target_port = number<br>      protocol    = string<br>    }))<br>  })</pre> | <pre>{<br>  "port": [<br>    {<br>      "name": "amqp",<br>      "port": 5672,<br>      "protocol": "TCP",<br>      "target_port": 5672<br>    },<br>    {<br>      "name": "dashboard",<br>      "port": 8161,<br>      "protocol": "TCP",<br>      "target_port": 8161<br>    },<br>    {<br>      "name": "openwire",<br>      "port": 61616,<br>      "protocol": "TCP",<br>      "target_port": 61616<br>    },<br>    {<br>      "name": "stomp",<br>      "port": 61613,<br>      "protocol": "TCP",<br>      "target_port": 61613<br>    },<br>    {<br>      "name": "mqtt",<br>      "port": 1883,<br>      "protocol": "TCP",<br>      "target_port": 1883<br>    }<br>  ],<br>  "replicas": 1<br>}</pre> | no |
| <a name="input_aws_ebs"></a> [aws\_ebs](#input\_aws\_ebs) | AWS EBS for shared storage between pods | <pre>object({<br>    availability_zone = string<br>    size              = number<br>    encrypted         = bool<br>    kms_key_id        = string<br>    tags              = object({})<br>  })</pre> | <pre>{<br>  "availability_zone": "eu-west-3a",<br>  "encrypted": true,<br>  "kms_key_id": "",<br>  "size": 5,<br>  "tags": {}<br>}</pre> | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | Profile of AWS credentials to deploy Terraform sources | `string` | `"default"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region where resources will be created | `string` | `"eu-west-3"` | no |
| <a name="input_k8s_config_context"></a> [k8s\_config\_context](#input\_k8s\_config\_context) | Context of K8s | `string` | `"default"` | no |
| <a name="input_k8s_config_path"></a> [k8s\_config\_path](#input\_k8s\_config\_path) | Path of the configuration file of K8s | `string` | `"~/.kube/config"` | no |
| <a name="input_mongodb"></a> [mongodb](#input\_mongodb) | Parameters of MongoDB | <pre>object({<br>    replicas = number<br>    port     = number<br>  })</pre> | <pre>{<br>  "port": 27017,<br>  "replicas": 1<br>}</pre> | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK storage resources | `string` | `"armonik-storage"` | no |
| <a name="input_redis"></a> [redis](#input\_redis) | Parameters of Redis | <pre>object({<br>    replicas = number<br>    port     = number<br>  })</pre> | <pre>{<br>  "port": 6379,<br>  "replicas": 1<br>}</pre> | no |
| <a name="input_storage"></a> [storage](#input\_storage) | List of storage for each ArmoniK data to be created. | `list(string)` | <pre>[<br>  "MongoDB"<br>]</pre> | no |
| <a name="input_storage_kubernetes_secrets"></a> [storage\_kubernetes\_secrets](#input\_storage\_kubernetes\_secrets) | List of Kubernetes secrets for the storage to be created | <pre>object({<br>    mongodb  = string<br>    redis    = string<br>    activemq = string<br>  })</pre> | <pre>{<br>  "activemq": "activemq-storage-secret",<br>  "mongodb": "",<br>  "redis": "redis-storage-secret"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_activemq_endpoint_url"></a> [activemq\_endpoint\_url](#output\_activemq\_endpoint\_url) | ActiveMQ |
| <a name="output_aws_ebs"></a> [aws\_ebs](#output\_aws\_ebs) | AWS EBS |
| <a name="output_mongodb_endpoint_url"></a> [mongodb\_endpoint\_url](#output\_mongodb\_endpoint\_url) | MongoDB |
| <a name="output_redis_endpoint_url"></a> [redis\_endpoint\_url](#output\_redis\_endpoint\_url) | Redis |
<!-- END_TF_DOCS -->