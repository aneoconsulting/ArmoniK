<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.72.0 |
| <a name="requirement_cloudinit"></a> [cloudinit](#requirement\_cloudinit) | >= 2.2.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.4.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.7.1 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 1.4.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.1.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 3.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.72.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks"></a> [eks](#module\_eks) | ./modules/eks | n/a |
| <a name="module_kms"></a> [kms](#module\_kms) | ../../modules/aws/kms | n/a |
| <a name="module_s3fs_bucket"></a> [s3fs\_bucket](#module\_s3fs\_bucket) | ./modules/s3 | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ./modules/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [random_string.random_resources](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_eks"></a> [eks](#input\_eks) | Parameters of AWS EKS | <pre>object({<br>    cluster_version                      = string<br>    cluster_endpoint_public_access       = bool<br>    cluster_endpoint_public_access_cidrs = list(string)<br>    cluster_log_retention_in_days        = number<br>  })</pre> | <pre>{<br>  "cluster_endpoint_public_access": true,<br>  "cluster_endpoint_public_access_cidrs": [<br>    "0.0.0.0/0"<br>  ],<br>  "cluster_log_retention_in_days": 30,<br>  "cluster_version": "1.21"<br>}</pre> | no |
| <a name="input_eks_worker_groups"></a> [eks\_worker\_groups](#input\_eks\_worker\_groups) | List of EKS worker node groups | `any` | <pre>[<br>  {<br>    "asg_desired_capacity": 0,<br>    "asg_max_size": 20,<br>    "asg_min_size": 0,<br>    "name": "worker-small-spot",<br>    "on_demand_base_capacity": 0,<br>    "override_instance_types": [<br>      "m5.xlarge",<br>      "m5d.xlarge",<br>      "m5a.xlarge"<br>    ],<br>    "spot_instance_pools": 0<br>  },<br>  {<br>    "asg_desired_capacity": 0,<br>    "asg_max_size": 20,<br>    "asg_min_size": 0,<br>    "name": "worker-2xmedium-spot",<br>    "on_demand_base_capacity": 0,<br>    "override_instance_types": [<br>      "m5.2xlarge",<br>      "m5d.2xlarge",<br>      "m5a.2xlarge"<br>    ],<br>    "spot_instance_pools": 0<br>  },<br>  {<br>    "asg_desired_capacity": 0,<br>    "asg_max_size": 20,<br>    "asg_min_size": 0,<br>    "name": "worker-4xmedium-spot",<br>    "on_demand_base_capacity": 0,<br>    "override_instance_types": [<br>      "m5.4xlarge",<br>      "m5d.4xlarge",<br>      "m5a.4xlarge"<br>    ],<br>    "spot_instance_pools": 0<br>  },<br>  {<br>    "asg_desired_capacity": 0,<br>    "asg_max_size": 20,<br>    "asg_min_size": 0,<br>    "name": "worker-8xmedium-spot",<br>    "on_demand_base_capacity": 0,<br>    "override_instance_types": [<br>      "m5.8xlarge",<br>      "m5d.8xlarge",<br>      "m5a.8xlarge"<br>    ],<br>    "spot_instance_pools": 0<br>  }<br>]</pre> | no |
| <a name="input_encryption_keys"></a> [encryption\_keys](#input\_encryption\_keys) | Encryption keys ARN for EKS components | <pre>object({<br>    cluster_log_kms_key_id    = string<br>    cluster_encryption_config = string<br>    ebs_kms_key_id            = string<br>  })</pre> | <pre>{<br>  "cluster_encryption_config": "",<br>  "cluster_log_kms_key_id": "",<br>  "ebs_kms_key_id": ""<br>}</pre> | no |
| <a name="input_profile"></a> [profile](#input\_profile) | Profile of AWS credentials to deploy Terraform sources | `string` | `"default"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region where the infrastructure will be deployed | `string` | `"eu-west-3"` | no |
| <a name="input_s3fs_bucket"></a> [s3fs\_bucket](#input\_s3fs\_bucket) | AWS S3 bucket to be used as filesystem shared between pods | <pre>object({<br>    name             = string<br>    kms_key_id       = string<br>    shared_host_path = string<br>    tags             = object({})<br>  })</pre> | <pre>{<br>  "kms_key_id": "",<br>  "name": "s3fs",<br>  "shared_host_path": "/data",<br>  "tags": {}<br>}</pre> | no |
| <a name="input_tag"></a> [tag](#input\_tag) | Tag to prefix the AWS resources | `string` | `null` | no |
| <a name="input_vpc"></a> [vpc](#input\_vpc) | Parameters of AWS VPC | <pre>object({<br>    # list of CIDR block associated with the private subnet<br>    cidr_block_private                              = list(string)<br>    # list of CIDR block associated with the public subnet<br>    cidr_block_public                               = list(string)<br>    # Main CIDR block associated to the VPC<br>    main_cidr_block                                 = string<br>    # cidr block associated with pod<br>    pod_cidr_block_private                          = list(string)<br>    enable_private_subnet                           = bool<br>    flow_log_cloudwatch_log_group_kms_key_id        = string<br>    flow_log_cloudwatch_log_group_retention_in_days = number<br>  })</pre> | <pre>{<br>  "cidr_block_private": [<br>    "10.0.0.0/18",<br>    "10.0.64.0/18",<br>    "10.0.128.0/18"<br>  ],<br>  "cidr_block_public": [<br>    "10.0.192.0/24",<br>    "10.0.193.0/24",<br>    "10.0.194.0/24"<br>  ],<br>  "enable_private_subnet": true,<br>  "flow_log_cloudwatch_log_group_kms_key_id": "",<br>  "flow_log_cloudwatch_log_group_retention_in_days": 30,<br>  "main_cidr_block": "10.0.0.0/16",<br>  "pod_cidr_block_private": [<br>    "10.1.0.0/16",<br>    "10.2.0.0/16",<br>    "10.3.0.0/16"<br>  ]<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eks"></a> [eks](#output\_eks) | n/a |
| <a name="output_kms"></a> [kms](#output\_kms) | n/a |
| <a name="output_s3_bucket_shared_storage"></a> [s3\_bucket\_shared\_storage](#output\_s3\_bucket\_shared\_storage) | n/a |
| <a name="output_vpc"></a> [vpc](#output\_vpc) | n/a |
<!-- END_TF_DOCS -->