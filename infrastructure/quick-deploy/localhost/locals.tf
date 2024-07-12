locals {
  config_list_control_plane    = [module.activemq, module.redis]
  config_list_polling_agent    = [module.activemq, module.redis]
  config_list_worker           = [module.activemq, module.redis]
  config_list_metrics_exporter = [module.activemq, module.redis]
  control_env                  = merge([for element in local.config_list_control_plane[0] : element.env]...)
  polling_env                  = merge([for element in local.config_list_polling_agent[0] : element.env]...)
  worker_env                   = merge([for element in local.config_list_worker[0] : element.env]...)
  metrics_env                  = merge([for element in local.config_list_metrics_exporter[0] : element.env]...)
  control_env_secret           = setunion([for element in local.config_list_control_plane[0] : element.env_secret]...)
  polling_env_secret           = setunion([for element in local.config_list_polling_agent[0] : element.env_secret]...)
  worker_env_secret            = setunion([for element in local.config_list_worker[0] : element.env_secret]...)
  metrics_env_secret           = setunion([for element in local.config_list_metrics_exporter[0] : element.env_secret]...)
  control_mount_secret         = merge([for element in local.config_list_control_plane[0] : element.mount_secret]...)
  polling_mount_secret         = merge([for element in local.config_list_polling_agent[0] : element.mount_secret]...)
  worker_mount_secret          = merge([for element in local.config_list_worker[0] : element.mount_secret]...)
  metrics_mount_secret         = merge([for element in local.config_list_metrics_exporter[0] : element.mount_secret]...)

}
