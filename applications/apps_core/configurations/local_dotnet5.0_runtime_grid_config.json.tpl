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
  "certificates_dir_path": "{{certificates_dir_path}}",
  "http_proxy": "{{http_proxy}}",
  "https_proxy": "{{https_proxy}}",
  "no_proxy": "{{no_proxy}}",
  "http_proxy_lower": "{{http_proxy_lower}}",
  "https_proxy_lower": "{{https_proxy_lower}}",
  "no_proxy_lower": "{{no_proxy_lower}}",
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