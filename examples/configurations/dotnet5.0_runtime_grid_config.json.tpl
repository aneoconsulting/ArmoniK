{
  "project_name": "{{image_tag}}",
  "grid_storage_service" : "REDIS",
  "grid_queue_service" : "{{grid_queue_service}}",
  "grid_queue_config" : "{'priorities':5}",
  "tasks_status_table_service": "{{tasks_status_table_service}}",
  "max_htc_agents": 100,
  "min_htc_agents": 1,
  "dynamodb_default_read_capacity" : 10,
  "dynamodb_default_write_capacity" : 10,
  "graceful_termination_delay":300,
  "certificates_dir_path": "{{certificates_dir_path}}",
  "eks_worker_groups" : [
      {
        "name"                    : "worker-small-spot",
        "override_instance_types" : ["m5.xlarge","m4.xlarge","m5d.xlarge","m5a.xlarge"],
        "spot_instance_pools"     : 0,
        "asg_min_size"            : 0,
        "asg_max_size"            : 20,
        "asg_desired_capacity"    : 1,
        "on_demand_base_capacity" : 0
      },
      {
        "name"                    : "worker-medium-spot",
        "override_instance_types" : ["m5.2xlarge","m5d.2xlarge", "m5a.2xlarge","m4.2xlarge"],
        "spot_instance_pools"     : 0,
        "asg_min_size"            : 0,
        "asg_max_size"            : 20,
        "asg_desired_capacity"    : 0,
        "on_demand_base_capacity" : 0

      },
      {
        "name"                    : "worker-medium-spot",
        "override_instance_types" : ["m5.4xlarge","m5d.4xlarge", "m5a.4xlarge","m4.4xlarge"],
        "spot_instance_pools"     : 0,
        "asg_min_size"            : 0,
        "asg_max_size"            : 20,
        "asg_desired_capacity"    : 0,
        "on_demand_base_capacity" : 0

      },
      {
        "name"                    : "worker-medium-spot",
        "override_instance_types" : ["m5.8xlarge","m5d.8xlarge", "m5a.8xlarge"],
        "spot_instance_pools"     : 0,
        "asg_min_size"            : 0,
        "asg_max_size"            : 20,
        "asg_desired_capacity"    : 0,
        "on_demand_base_capacity" : 0

      }
  ],
  "agent_configuration": {
    "lambda": {
      "minCPU": "800",
      "maxCPU": "900",
      "minMemory": "1200",
      "maxMemory": "1900",
      "location" : "s3://{{workload_bucket_name}}/lambda.zip",
      "runtime": "5.0.4",
      "lambda_handler_file_name" :"{{dotnet50_file_handler}}",
      "function_name" : "function",
      "lambda_handler_function_name" : "function"
    }
  },
  "enable_private_subnet" : true,
  "vpc_cidr_block_public" :["10.0.192.0/24", "10.0.193.0/24", "10.0.194.0/24"],
  "vpc_main_cidr_block": "10.0.0.0/16",
  "vpc_cidr_block_private" :["10.0.0.0/18","10.0.64.0/18", "10.0.128.0/18"],
  "vpc_pod_cidr_block_private" :["10.1.0.0/16","10.2.0.0/16", "10.3.0.0/16"],
  "input_role":[
      {
        "rolearn"  : "arn:aws:iam::{{account_id}}:role/Admin",
        "username" : "lambda",
        "groups"   : ["system:masters"]
      }
  ]
}