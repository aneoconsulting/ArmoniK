# The Pub/Sub queue of every partition, created here before Core uses it. Core creates the topic <prefix>-<partition>
# when it first publishes, but the subscription <topic>-ak-sub only when the first polling agent of the partition
# starts: the tasks submitted to a partition still at 0 pod, before any subscription exists, are published to a topic
# nobody subscribes to and lost (Pub/Sub delivers only what is published after a subscription is created). Core gets
# AlreadyExists for both and goes on. They also go away with the stack instead of outliving it.
# Same settings as Core's defaults (Adaptors/PubSub/src/PubSub.cs).

locals {
  # The chart's own partitions (variables.tf) and those of var.partitions
  queue_partitions = toset(concat(["default", "stream", "htcmock"], keys(var.partitions)))
}

resource "google_pubsub_topic" "partitions" {
  for_each = local.queue_partitions

  project                    = var.project
  name                       = "${var.prefix}-${each.key}"
  message_retention_duration = "86400s"
  labels                     = local.labels

  depends_on = [terraform_data.apis]
}

resource "google_pubsub_subscription" "partitions" {
  for_each = local.queue_partitions

  project              = var.project
  name                 = "${google_pubsub_topic.partitions[each.key].name}-ak-sub"
  topic                = google_pubsub_topic.partitions[each.key].id
  ack_deadline_seconds = 120
  labels               = local.labels

  # GCP deletes a subscription idle for 31 days by default: a partition unused for a month would lose its next tasks
  expiration_policy {
    ttl = ""
  }
}
