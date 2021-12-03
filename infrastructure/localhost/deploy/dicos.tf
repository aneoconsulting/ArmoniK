locals {
  storage = {
    allowed_object_storage         = [
      "MongoDB",
      "Redis"
    ]
    allowed_table_storage          = [
      "MongoDB"
    ]
    allowed_queue_storage          = [
      "MongoDB",
      "ActiveMQ"
    ]
    allowed_lease_provider_storage = [
      "MongoDB"
    ]
  }
}