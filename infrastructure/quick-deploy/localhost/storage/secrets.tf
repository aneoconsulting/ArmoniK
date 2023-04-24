resource "kubernetes_secret" "shared_storage" {
  metadata {
    name      = "shared-storage"
    namespace = var.namespace
  }
  data = {
    host_path         = local.shared_storage_host_path
    file_storage_type = local.shared_storage_file_storage_type
    file_server_ip    = local.shared_storage_file_server_ip
  }
}

resource "kubernetes_secret" "deployed_object_storage" {
  metadata {
    name      = "deployed-object-storage"
    namespace = var.namespace
  }
  data = {
    list    = join(",", local.deployed_object_storages)
    adapter = local.object_storage_adapter
  }
}

resource "kubernetes_secret" "deployed_table_storage" {
  metadata {
    name      = "deployed-table-storage"
    namespace = var.namespace
  }
  data = {
    list    = join(",", local.deployed_table_storages)
    adapter = local.table_storage_adapter
  }
}

resource "kubernetes_secret" "deployed_queue_storage" {
  metadata {
    name      = "deployed-queue-storage"
    namespace = var.namespace
  }
  data = {
    list                  = join(",", local.deployed_queue_storages)
    adapter               = local.queue_storage_adapter
    adapter_class_name    = module.activemq.adapter_class_name
    adapter_absolute_path = module.activemq.adapter_absolute_path
  }
}