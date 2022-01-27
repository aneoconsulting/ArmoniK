<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.72.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.4.1 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 1.4.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.72.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.4.1 |
| <a name="provider_local"></a> [local](#provider\_local) | >= 1.4.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_node_termination_handler_role"></a> [aws\_node\_termination\_handler\_role](#module\_aws\_node\_termination\_handler\_role) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | 4.1.0 |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 17.24.0 |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_lifecycle_hook.aws_node_termination_handler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_lifecycle_hook) | resource |
| [aws_cloudwatch_event_rule.aws_node_termination_handler_asg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.aws_node_termination_handler_spot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_iam_policy.aws_node_termination_handler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.worker_assume_role_agent_permissions_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.worker_autoscaling_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.worker_assume_role_agent_permissions_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.workers_autoscaling_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [helm_release.aws_node_termination_handler](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.eni_config](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [null_resource.change_cni_label](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.patch_coredns](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.trigger_custom_cni](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.update_kubeconfig](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_eks_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_policy_document.aws_node_termination_handler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.worker_assume_role_agent_permissions_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.worker_autoscaling_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [local_file.patch_core_dns](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_eks"></a> [eks](#input\_eks) | Parameters of AWS EKS | <pre>object({<br>    region                               = string<br>    cluster_name                         = string<br>    cluster_version                      = string<br>    vpc_private_subnet_ids               = list(string)<br>    vpc_id                               = string<br>    pods_subnet_ids                      = list(string)<br>    enable_private_subnet                = bool<br>    cluster_endpoint_public_access       = bool<br>    cluster_endpoint_public_access_cidrs = list(string)<br>    encryption_keys                      = object({<br>      cluster_log_kms_key_id    = string<br>      cluster_encryption_config = string<br>      ebs_kms_key_id            = string<br>    })<br>    cluster_log_retention_in_days        = number<br>    tags                                 = map(string)<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_certificate_authority"></a> [certificate\_authority](#output\_certificate\_authority) | Endpoint for EKS control plane |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Endpoint for EKS control plane |
| <a name="output_eks_cluster"></a> [eks\_cluster](#output\_eks\_cluster) | EKS object |
| <a name="output_token"></a> [token](#output\_token) | Authentication token for EKS |
<!-- END_TF_DOCS -->