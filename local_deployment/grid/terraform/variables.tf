variable "k8s_config_context" {
  default = "default"
  description = ""
}

variable "k8s_config_path" {
  default = "~/.kube/config"
  description = ""
}

variable "cluster_name" {
  default = "armonik"
  description = "Name of EKS cluster in AWS"
}

variable "config_name" {
  default = "htc"
  description = "Default path for the SSM parameter storing the configuration of the grid"
}

variable "lambda_runtime" {
  default     = "python3.7"
  description = "Lambda runtine"
}

variable "lambda_timeout" {
  default = 300
  description = "Lambda function timeout"
}

variable "kubernetes_version" {
  default = "1.20"
  description = "Name of EKS cluster in AWS"
}

variable "k8s_ca_version" {
  default  = "v1.20.0"
  description = "Cluster autoscaler version"
}

variable "docker_registry" {
  default = ""
  description = "URL of Amazon ECR image repostiories"
}

variable "tasks_status_table_config" {
  default  = "{}"
  description = "Custom configuration for status table"
}

variable "ddb_status_table" {
  default  = "armonik_tasks_status_table"
  description = "htc DinamoDB table name"
}

variable "tasks_status_table_service" {
  default  = "MongoDB"
  description = "Status table sertvice"
}

variable "queue_name" {
  default  = "armonik_task_queue"
  description = "Armonik queue name"
}

variable "dlq_name" {
  default  = "armonik_task_queue_dlq"
  description = "Armonikredis_with_ssl queue dlq name"
}

variable "grid_storage_service" {
  default = "REDIS"
  description = "Configuration string for internal results storage system"
}

variable "grid_queue_service" {
  default = "RSMQ"
  description = "Configuration string for the type of queuing service to be used"
}

variable "grid_queue_config" {
  default = "{'sample':5}"
  description = "dictionary queue config"
}

variable "lambda_name_ttl_checker" {
  default  = "ttl_checker"
  description = "Lambda name for ttl checker"
}

variable "lambda_name_submit_tasks" {
  default  = "submit_task"
  description = "Lambda name for submit task"
}

variable "lambda_name_get_results" {
  default  = "get_results"
  description = "Lambda name for get result task"
}

variable "lambda_name_cancel_tasks" {
  default  = "cancel_tasks"
  description = "Lambda name for cancel tasks"
}

variable "lambda_alb_name" {
  default = "lambda-frontend"
  description = "Name of the load balancer for Lambdas"
}

variable "metrics_are_enabled" {
  default  = "0"
  description = "If set to True(1) then metrics will be accumulated and delivered downstream for visualisation"
}

variable "metrics_submit_tasks_lambda_connection_string" {
  default  = "influxdb 8086 measurementsdb submit_tasks"
  description = "The type and the connection string for the downstream"
}

variable "metrics_cancel_tasks_lambda_connection_string" {
  default  = "influxdb 8086 measurementsdb cancel_tasks"
  description = "The type and the connection string for the downstream"
}

variable "metrics_get_results_lambda_connection_string" {
  default  = "influxdb 8086 measurementsdb get_results"
  description = "The type and the connection string for the downstream"
}

variable "metrics_ttl_checker_lambda_connection_string" {
  default  = "influxdb 8086 measurementsdb ttl_checker"
  description = "The type and the connection string for the downstream"
}

variable "agent_use_congestion_control" {
  description = "Use Congestion Control protocol at pods to avoid overloading DDB"
  default = "0"
}

variable "htc_agent_name" {
  default = "armonik-agent"
  description = "name of the htc agent to scale out/in"
}

variable "suffix" {
  default = ""
  description = "suffix for generating unique name for AWS resource"
}

variable "max_htc_agents" {
  description = "maximum number of agents that can run on EKS"
  default = 100
}

variable "min_htc_agents" {
  description = "minimum number of agents that can run on EKS"
  default = 1
}

variable "htc_agent_target_value" {
  description = "target value for the load on the system"
  default = 2
}

variable "graceful_termination_delay" {
  description = "graceful termination delay in second for scaled in action"
  default = 30
}

variable "empty_task_queue_backoff_timeout_sec" {
  description = "agent backoff timeout in second"
  default = 0.5
}

variable "work_proc_status_pull_interval_sec" {
  description = "agent pulling interval"
  default = 0.5
}

variable "task_ttl_expiration_offset_sec" {
  description = "agent TTL for task to time out in second"
  default = 30
}

variable "task_ttl_refresh_interval_sec" {
  description = "reset interval for agent TTL"
  default = 5.0
}

variable "agent_sqs_visibility_timeout_sec" {
  description = "default visibility timeout for SQS messages"
  default = 3600
}

variable "task_input_passed_via_external_storage" {
  description = "Indicator for passing the args through stdin"
  default = 1
}

variable "metrics_pre_agent_connection_string" {
  description = "pre agent connection string for monitoring"
  default = "influxdb 8086 measurementsdb agent_pre"
}

variable "metrics_post_agent_connection_string" {
  description = "post agent connection string for monitoring"
  default = "influxdb 8086 measurementsdb agent_post"
}

variable "agent_configuration_filename" {
  description = "filename were agent configuration (in json) is going to be stored"
  default = "Agent_config.json"
}

variable "client_configuration_filename" {
  description = "filename were client configuration (in json) is going to be stored"
  default = "Client_config.json"
}

variable "enable_xray" {
  description = "Enable XRAY at the agent level"
  type = number
  default = 0
}

variable "agent_configuration" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = any
  default = {}
}

variable "project_name" {
  description = "name of project"
  type=string
  default = ""
}

variable "mongodb_port" {
  description = "mongodb port"
  type = number
  default = 27017
}

variable "redis_port" {
  description = "Port for Redis instance"
  default = 6379
  type = number
}

variable "queue_port" {
  description = "Port for queue instance"
  default = 6380
  type = number
}

variable "cancel_tasks_port" {
  description = "Port for Cancel Tasks Lambda function"
  default = 9000
  type = number
}

variable "submit_task_port" {
  description = "Port for Submit Task Lambda function"
  type = number
  default = 9001
}

variable "get_results_port" {
  description = "Port for Get Results Lambda function"
  type = number
  default = 9002
}

variable "ttl_checker_port" {
  description = "Port for TTL Checker Lambda function"
  type = number
  default = 9003
}

variable "redis_with_ssl" {
  type = bool
  default = true
  description = "redis with ssl"
}

variable "connection_redis_timeout" {
  description = "connection redis timeout"
  default = 10000
}

variable "certificates_dir_path" {
  default = ""
  description = "Path of the directory containing the certificates redis.crt, redis.key, ca.crt"
}

variable "redis_ca_cert" {
  description = "path to the authority certificate file (ca.crt) of the redis server in the docker machine"
  default = "/redis_certificates/ca.crt"
}

variable "redis_client_pfx" {
  description = "path to the client certificate file (certificate.pfx) of the redis server in the docker machine"
  default = "/redis_certificates/certificate.pfx"
}

variable "redis_key_file" {
  description = "path to the authority certificate file (redis.key) of the redis server in the docker machine"
  default = "/redis_certificates/redis.key"
}

variable "redis_cert_file" {
  description = "path to the client certificate file (redis.crt) of the redis server in the docker machine"
  default = "/redis_certificates/redis.crt"
}

variable "cluster_config" {
  description = "Configuration type of the cluster (local, cloud, cluster)"
  default = "local"
}

variable "nginx_port" {
  description = "Port for nginx instance"
  default = 9080
  type = number
}

variable "nginx_endpoint_url" {
  description = "Url for nginx instance"
  default = "http://ingress-nginx-controller.ingress-nginx"
  type = string
}

variable "image_pull_policy" {
  description = "Pull image policy"
  default = "IfNotPresent"
  type = string
}

variable "api_gateway_service" {
  description = "API Gateway Service"
}
