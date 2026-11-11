# Autoscaling of the partitions (autoscaling/README.md): the targets in PromQL, as recording rules, and what a
# partition of var.partitions selects with its "autoscaling" block: the law KEDA reads, and how the HPA applies it.
# The rules compute the three laws for every partition, selected or not, the chart's own included.

locals {
  autoscaling_params = ["catchup_seconds", "utilization", "startup_seconds", "queue_target"]

  # armonik:scaler_config{partition, param}: the parameters a partition sets, the rules default the others
  autoscaling_config_rules = flatten([
    for name, p in var.partitions : [
      for param in local.autoscaling_params : {
        record = "armonik:scaler_config"
        expr   = "vector(${p.autoscaling[param]})"
        labels = { partition = name, param = param }
      } if p.autoscaling[param] != null
    ]
  ])

  # law = "dual" or "model": the trigger reads the law in Prometheus, 1 per pod. Prometheus is then in the scaling
  # path: an empty answer (rules not loaded yet, exporter or Prometheus down) is an error, not 0, and after 3 of them
  # KEDA keeps the pods there are instead of scaling down. law = "queue" keeps the chart's trigger, which reads the
  # metrics exporter directly.
  autoscaling_law_values = {
    compute-plane = {
      partitions = {
        for name, p in var.partitions : name => {
          hpa = {
            fallback = { failureThreshold = 3, replicas = 1, behavior = "currentReplicasIfHigher" }
            triggers = [{
              type = "prometheus"
              metadata = {
                serverAddress       = "{{ include \"armonik.monitoring.prometheusUrl\" . }}"
                query               = "armonik:scaler_target{partition=\"${name}\",law=\"${p.autoscaling.law}\"}"
                threshold           = "1"
                activationThreshold = "0"
                ignoreNullValues    = "false"
              }
            }]
          }
        } if p.autoscaling.law != "queue"
      }
    }
  }

  # How the HPA applies the target. The chart's own (hpa = "chart"): no limit up, 300 s before a scale-down.
  autoscaling_hpa_profiles = {
    # The target as it is: no limit up, an idle pod kept about one pod start
    fast = {
      pollingInterval = 5
      cooldownPeriod  = 60
      advanced = {
        horizontalPodAutoscalerConfig = {
          behavior = {
            scaleUp = {
              stabilizationWindowSeconds = 0
              selectPolicy               = "Max"
              # Percent alone starts from the current count: 1 -> 11 -> 100 waits a period; Pods adds 100 at once
              policies = [{ type = "Percent", value = 1000, periodSeconds = 15 }, { type = "Pods", value = 100, periodSeconds = 15 }]
            }
            scaleDown = {
              stabilizationWindowSeconds = 60
              policies                   = [{ type = "Percent", value = 100, periodSeconds = 15 }]
            }
          }
        }
      }
    }
    # A burst is taken in progressively: at most twice the pods (or 4 more) every 15 s, so that the first pods
    # measure the duration of the tasks before the bulk of the pods, and of the nodes, is asked for
    ramp = {
      pollingInterval = 5
      cooldownPeriod  = 60
      advanced = {
        horizontalPodAutoscalerConfig = {
          behavior = {
            scaleUp = {
              stabilizationWindowSeconds = 0
              selectPolicy               = "Max"
              policies                   = [{ type = "Percent", value = 100, periodSeconds = 15 }, { type = "Pods", value = 4, periodSeconds = 15 }]
            }
            scaleDown = {
              stabilizationWindowSeconds = 60
              policies                   = [{ type = "Percent", value = 100, periodSeconds = 15 }]
            }
          }
        }
      }
    }
  }

  autoscaling_hpa_values = {
    compute-plane = {
      partitions = {
        for name, p in var.partitions : name => { hpa = local.autoscaling_hpa_profiles[p.autoscaling.hpa] }
        if p.autoscaling.hpa != "chart"
      }
    }
  }
}

resource "kubectl_manifest" "autoscaling_rules" {
  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "armonik-autoscaling"
      namespace = local.namespaces.operators
      # The ruleSelector of the operators' Prometheus
      labels = { release = "armonik-operators" }
    }
    spec = {
      groups = concat(
        yamldecode(file("${path.module}/autoscaling/rules.yaml")).groups,
        length(local.autoscaling_config_rules) == 0 ? [] : [{
          name     = "armonik-autoscaling-config"
          interval = "30s"
          rules    = local.autoscaling_config_rules
        }],
      )
    }
  })

  depends_on = [helm_release.armonik_operators]
}
