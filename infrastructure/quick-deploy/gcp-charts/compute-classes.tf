# ComputeClasses: GKE creates the node pools of a class when its pods are Pending, from the first rule of
# "priorities" with capacity, and removes them once empty. The nodes of a class are tainted with
# cloud.google.com/compute-class=<class>:NoSchedule, so only the pods that select it run there.
#
#   default   every pod selecting no class (cluster default class of the gke module): operators, control plane,
#             ingress, monitoring
#   workers   the partitions, selected in values/armonik.yaml; Spot first. A preempted node loses its running tasks,
#             which Core retries. Partition pods carry safe-to-evict "false", so neither the consolidation nor the
#             migration to a better rule ends a task: a node goes away once KEDA has scaled its pods in.
locals {
  compute_classes = {
    default = {
      priorities = [for family in var.node_classes.default.machine_families : {
        machineFamily = family
        minCores      = var.node_classes.default.min_cores
      }]
      activeMigration = { optimizeRulePriority = true }
    }
    workers = {
      priorities = concat(
        [for family in var.node_classes.workers.machine_families : {
          machineFamily = family
          spot          = true
          minCores      = var.node_classes.workers.min_cores
        }],
        var.node_classes.workers.on_demand_fallback ? [{
          machineFamily = var.node_classes.workers.machine_families[0]
          spot          = false
          minCores      = var.node_classes.workers.min_cores
        }] : [],
      )
      activeMigration   = { optimizeRulePriority = true }
      autoscalingPolicy = { consolidationDelayMinutes = 5 }
    }
  }
}

resource "kubectl_manifest" "compute_class" {
  for_each = local.compute_classes

  yaml_body = yamlencode({
    apiVersion = "cloud.google.com/v1"
    kind       = "ComputeClass"
    metadata = {
      name   = each.key
      labels = { "app.kubernetes.io/part-of" = "armonik" }
    }
    spec = merge(each.value, {
      nodePoolAutoCreation = { enabled = true }
      # Never outside the rules above: no on-demand node for the workers unless on_demand_fallback
      whenUnsatisfiable = "DoNotScaleUp"
      # Otherwise GKE picks the Compute Engine default service account for the node pools it creates
      nodePoolConfig = { serviceAccount = module.gke.service_account }
    })
  })
}
