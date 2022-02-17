locals {
  data_type = {
    object_mongodb         = (var.storage.data_type.object == "mongodb" && contains(var.storage.list, "mongodb"))
    object_redis           = (var.storage.data_type.object == "redis" && contains(var.storage.list, "redis"))
    table_mongodb          = (var.storage.data_type.table == "mongodb" && contains(var.storage.list, "mongodb"))
    queue_mongodb          = (var.storage.data_type.queue == "mongodb" && contains(var.storage.list, "mongodb"))
    queue_amqp             = (var.storage.data_type.queue == "amqp" && contains(var.storage.list, "amqp"))
    lease_provider_mongodb = (var.storage.data_type.lease_provider == "mongodb" && contains(var.storage.list, "mongodb"))
    shared_host_path       = (var.storage.data_type.shared == "hostpath")
    shared_nfs             = (var.storage.data_type.shared == "nfs")
    shared_aws_ebs         = (var.storage.data_type.shared == "aws_ebs")
  }
}