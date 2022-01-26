<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_external"></a> [external](#provider\_external) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_deployment.seq](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_service.seq](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [external_external.seq_node_ip](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK monitoring | `string` | n/a | yes |
| <a name="input_seq"></a> [seq](#input\_seq) | Parameters of Seq | <pre>object({<br>    replicas = number<br>    port     = list(object({<br>      name        = string<br>      port        = number<br>      target_port = number<br>      protocol    = string<br>    }))<br>  })</pre> | <pre>{<br>  "port": [<br>    {<br>      "name": "ingestion",<br>      "port": 5341,<br>      "protocol": "TCP",<br>      "target_port": 5341<br>    },<br>    {<br>      "name": "web",<br>      "port": 8080,<br>      "protocol": "TCP",<br>      "target_port": 80<br>    }<br>  ],<br>  "replicas": 1<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_seq"></a> [seq](#output\_seq) | Seq |
| <a name="output_seq_url"></a> [seq\_url](#output\_seq\_url) | n/a |
| <a name="output_seq_web_url"></a> [seq\_web\_url](#output\_seq\_web\_url) | n/a |
<!-- END_TF_DOCS -->