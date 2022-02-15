# Storage
output "storage_endpoint_url" {
  description = "Storage endpoints URLS"
  value       = {
    mongodb = {
      url                = module.mongodb.url
      host               = module.mongodb.host
      port               = module.mongodb.port
      allow_insecure_tls = false
      certificates       = {
        secret      = module.mongodb.user_certificate.secret
        ca_filename = module.mongodb.user_certificate.ca_filename
      }
      credentials        = {
        secret       = module.mongodb.user_credentials.secret
        username_key = module.mongodb.user_credentials.username_key
        password_key = module.mongodb.user_credentials.password_key
      }
    }
  }
}
