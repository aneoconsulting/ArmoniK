locals {
  config_list_control_plane    = concat(module.activemq, module.nfs)
  config_list_polling_agent    = concat(module.activemq, module.nfs)
  config_list_worker           = []
  config_list_metrics_exporter = concat(module.activemq, module.nfs)
}
