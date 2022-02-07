output "mq" {
  description = "AWS MQ object"
  value       = aws_mq_broker.mq
}

# MQ
output "activemq_endpoint_url" {
  description = "AWS MQ (ActiveMQ) endpoint urls"
  value       = {
    url  = aws_mq_broker.mq.instances.0.endpoints.1
    host = trim(split(":", aws_mq_broker.mq.instances.0.endpoints.1).1, "//")
    port = tonumber(split(":", aws_mq_broker.mq.instances.0.endpoints.1).2)
  }
}

output "mq_name" {
  description = "Name of MQ cluster"
  value       = aws_mq_broker.mq.broker_name
}

output "kms_key_id" {
  description = "ARN of KMS used for MQ"
  value       = aws_mq_broker.mq.encryption_options.0.kms_key_id
}