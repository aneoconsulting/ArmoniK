# Autoscaling of the partitions (autoscaling/README.md): the targets in PromQL, as recording rules, and what a
# partition of var.partitions selects with its "autoscaling" block: the law KEDA reads, and how the HPA applies it.
# The rules compute both laws for every partition, selected or not, the chart's own included.
# Nothing of it without var.autoscaling_laws: the partitions keep the chart's trigger and HPA.

locals {
  # The autoscaling blocks read, none when the laws are off
  autoscaling = { for name, p in var.partitions : name => p.autoscaling if var.autoscaling_laws }

  autoscaling_params = ["catchup_seconds", "utilization", "startup_seconds"]

  # armonik:scaler_config{partition, param}: the parameters a partition sets, the rules default the others
  autoscaling_config_rules = flatten([
    for name, p in local.autoscaling : [
      for param in local.autoscaling_params : {
        record = "armonik:scaler_config"
        expr   = "vector(${p[param]})"
        labels = { partition = name, param = param }
      } if p[param] != null
    ]
  ])

  # The trigger reads the selected law in Prometheus, 1 per pod, for both laws: queue is the chart's formula
  # (ceil(queued / 2)) through the same path as model, so that two partitions compare their laws and not two triggers
  # (the chart's metrics-api trigger took ~2.5 min to act from 0 in the bench). Prometheus is then in the scaling
  # path: an empty answer (rules not loaded yet, exporter or Prometheus down) is an error, not 0, and after 3 of them
  # KEDA keeps the pods there are instead of scaling down.
  autoscaling_law_values = {
    compute-plane = {
      partitions = {
        for name, p in local.autoscaling : name => {
          hpa = {
            fallback = { failureThreshold = 3, replicas = 1, behavior = "currentReplicasIfHigher" }
            triggers = [{
              type = "prometheus"
              metadata = {
                serverAddress       = "{{ include \"armonik.monitoring.prometheusUrl\" . }}"
                query               = "armonik:scaler_target{partition=\"${name}\",law=\"${p.law}\"}"
                threshold           = "1"
                activationThreshold = "0"
                ignoreNullValues    = "false"
              }
            }]
          }
        }
      }
    }
  }

  # How the HPA applies the target. The chart's own (hpa = "chart"): no limit up, 300 s before a scale-down.
  autoscaling_hpa_profiles = {
    # The target as it is: no limit up. Down, an idle pod is kept 5 min: what is paid is its node, which only goes
    # away once every pod on it has, so a pod removed earlier saves nothing and is started again at the next burst
    # (bench g2-graph-stairs, 60 s: 150 -> 7 -> 84 pods between two levels of a graph, with the same nodes all along).
    # The nodes then go away 1 min after their pods (compute-classes.tf): about 6 min in all, as before.
    fast = {
      pollingInterval = 5
      cooldownPeriod  = 300
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
              stabilizationWindowSeconds = 300
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
      cooldownPeriod  = 300
      advanced = {
        horizontalPodAutoscalerConfig = {
          behavior = {
            scaleUp = {
              stabilizationWindowSeconds = 0
              selectPolicy               = "Max"
              policies                   = [{ type = "Percent", value = 100, periodSeconds = 15 }, { type = "Pods", value = 4, periodSeconds = 15 }]
            }
            scaleDown = {
              stabilizationWindowSeconds = 300
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
        for name, p in local.autoscaling : name => { hpa = local.autoscaling_hpa_profiles[p.hpa] }
        if p.hpa != "chart"
      }
    }
  }
}

resource "kubectl_manifest" "autoscaling_rules" {
  count = var.autoscaling_laws ? 1 : 0

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
