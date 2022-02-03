output "armonik_deployment" {
  description = "ArmoniK control plane URL"
  value       = (var.deploy.armonik ? {
    armonik_control_plane_url = module.armonik.0.control_plane_url
    seq_web_url               = (var.deploy.monitoring ? module.seq.0.web_url : var.seq_endpoints.web_url)
  } : {})
}

output "storage_endpoint_url" {
  description = "Storage endpoint URLS"
  value       = (var.deploy.storage ? {
    activemq = {
      url  = module.activemq.0.url
      host = module.activemq.0.host
      port = module.activemq.0.port
    }
    mongodb  = {
      url  = module.mongodb.0.url
      host = module.mongodb.0.host
      port = module.mongodb.0.port
    }
    redis    = {
      url  = module.redis.0.url
      host = module.redis.0.host
      port = module.redis.0.port
    }
  } : {})
}

# Seq endpoint URLS
output "seq_endpoints" {
  description = "Seq endpoint URLS"
  value       = (var.deploy.monitoring ? {
    url     = module.seq.0.url
    host    = module.seq.0.host
    port    = module.seq.0.port
    web_url = module.seq.0.web_url
  } : {})
}

