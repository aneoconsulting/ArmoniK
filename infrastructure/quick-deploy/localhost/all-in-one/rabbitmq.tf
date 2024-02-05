# Chaos Mesh
module "rabbitmq" {
  count     = var.rabbitmq.enable ? 1 : 0
  source    = "./generated/infra-modules/storage/onpremise/rabbitmq"
  namespace = var.rabbitmq.namespace
  docker_image = {
    rabbitmq = {
      image = var.rabbitmq.rabbitmq_image_name
      tag   = try(coalesce(var.rabbitmq.rabbitmq_image_tag), local.default_tags[var.rabbitmq.rabbitmq_image_name])
    }
  }
  helm_chart_repository = try(coalesce(var.rabbitmq.helm_chart_repository), var.helm_charts.rabbitmq.repository)
  helm_chart_version    = try(coalesce(var.rabbitmq.helm_chart_verison), var.helm_charts.rabbitmq.version)
  service_type          = var.rabbitmq.service_type
}

data "external" "get_rabbitmq_epmd_port" {
  program    = ["sh", "-c", "kubectl get svc rabbitmq -n rabbitmq -o jsonpath='{\"{\"}\"port\": \"{.spec.ports[0].port}\"}'"]
  depends_on = [module.rabbitmq]
}

data "external" "get_rabbitmq_amqp_port" {
  program    = ["sh", "-c", "kubectl get svc rabbitmq -n rabbitmq -o jsonpath='{\"{\"}\"port\": \"{.spec.ports[1].port}\"}'"]
  depends_on = [module.rabbitmq]
}

data "external" "get_rabbitmq_dist_port" {
  program    = ["sh", "-c", "kubectl get svc rabbitmq -n rabbitmq -o jsonpath='{\"{\"}\"port\": \"{.spec.ports[1].port}\"}'"]
  depends_on = [module.rabbitmq]
}

data "external" "get_rabbitmq_stats_port" {
  program    = ["sh", "-c", "kubectl get svc rabbitmq -n rabbitmq -o jsonpath='{\"{\"}\"port\": \"{.spec.ports[2].port}\"}'"]
  depends_on = [module.rabbitmq]
}

data "external" "get_rabbitmq_ip" {
  program    = ["sh", "-c", "kubectl get svc rabbitmq -n rabbitmq -o jsonpath='{\"{\"}\"ip\": \"{.spec.clusterIP}\"}'"]
  depends_on = [module.rabbitmq]
}