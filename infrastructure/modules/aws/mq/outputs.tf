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

output "web_url" {
  description = "The URL of the broker's ActiveMQ Web Console"
  value       = aws_mq_broker.mq.instances.0.console_url
}

output "creds" {
  description = "User credentials in encrypted file"
  value       = {
    file       = module.creds.encrypted_file
    kms_key_id = module.creds.kms_key_id
  }
}