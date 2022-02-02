output "armonik_deployment" {
  description = "Outputs of ArmoniK deployment on local machine"
  value       = {
    activemq                  = {
      url  = module.activemq.url
      host = module.activemq.host
      port = module.activemq.port
    }
    mongodb                   = {
      url  = module.mongodb.url
      host = module.mongodb.host
      port = module.mongodb.port
    }
    redis                     = {
      url  = module.redis.url
      host = module.redis.host
      port = module.redis.port
    }
    seq_web_url               = module.seq.web_url
    armonik_control_plane_url = module.armonik.control_plane_url
  }
}

