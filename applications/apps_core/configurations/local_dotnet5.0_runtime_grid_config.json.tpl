{
  "project_name": "{{image_tag}}",
  "grid_storage_service" : "REDIS",
  "grid_queue_service" : "{{grid_queue_service}}",
  "grid_queue_config" : "{'priorities':5}",
  "tasks_status_table_service": "{{tasks_status_table_service}}",
  "api_gateway_service": "{{api_gateway_service}}",
  "max_htc_agents": 100,
  "min_htc_agents": 1,
  "graceful_termination_delay":300,
  "docker_registry":"{{docker_registry}}",
  "certificates_dir_path": "{{certificates_dir_path}}",
  "cluster_config": "{{cluster_config}}",
  "image_pull_policy": "{{image_pull_policy}}",
  "agent_configuration": {
    "lambda": {
      "minCPU": "50",
      "maxCPU": "900",
      "minMemory": "100",
      "maxMemory": "1900",
      "runtime": "5.0.4",
      "lambda_handler_file_name" :"{{dotnet50_file_handler}}",
      "function_name" : "function",
      "lambda_handler_function_name" : "function"
    }
  }
}