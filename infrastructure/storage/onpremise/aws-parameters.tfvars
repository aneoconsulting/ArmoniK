# Namespace of ArmoniK storage
namespace = "armonik-storage"

# Storage resources to be created
storage = ["MongoDB", "Amqp", "Redis"]

# MongoDB
mongodb = {
  replicas = 1
  port     = 27017
  image    = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/mongodb"
  tag      = "4.4.11"
  secret   = "mongodb-storage-secret"
}

# Parameters for Redis
redis = {
  replicas = 1
  port     = 6379
  image    = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/redis"
  tag      = "bullseye"
  secret   = "redis-storage-secret"
}

# Parameters for ActiveMQ
activemq = {
  replicas = 1
  port     = [
    { name = "amqp", port = 5672, target_port = 5672, protocol = "TCP" },
    { name = "dashboard", port = 8161, target_port = 8161, protocol = "TCP" },
    { name = "openwire", port = 61616, target_port = 61616, protocol = "TCP" },
    { name = "stomp", port = 61613, target_port = 61613, protocol = "TCP" },
    { name = "mqtt", port = 1883, target_port = 1883, protocol = "TCP" }
  ]
  image    = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/activemq"
  tag      = "5.16.3"
  secret   = "activemq-storage-secret"
}

