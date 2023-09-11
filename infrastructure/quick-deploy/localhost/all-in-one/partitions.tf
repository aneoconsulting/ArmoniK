locals {
  compute_plane = {
    for name, partition in var.compute_plane :
    name => {
      replicas                         = try(coalesce(partition.replicas), coalesce(var.compute_plane_defaults.replicas), 1)
      termination_grace_period_seconds = try(coalesce(partition.termination_grace_period_seconds), coalesce(var.compute_plane_defaults.termination_grace_period_seconds), 30)
      image_pull_secrets               = try(coalesce(partition.image_pull_secrets), coalesce(var.compute_plane_defaults.image_pull_secrets), "")
      node_selector                    = try(coalesce(partition.node_selector), coalesce(var.compute_plane_defaults.node_selector), {})
      annotations                      = try(coalesce(partition.annotations), coalesce(var.compute_plane_defaults.annotations), {})
      polling_agent = {
        image             = try(coalesce(partition.polling_agent.image), coalesce(var.compute_plane_defaults.polling_agent.image), "dockerhubaneo/armonik_pollingagent")
        tag               = try(coalesce(partition.polling_agent.tag), coalesce(var.compute_plane_defaults.polling_agent.tag), null)
        image_pull_policy = try(coalesce(partition.polling_agent.image_pull_policy), coalesce(var.compute_plane_defaults.polling_agent.image_pull_policy), "IfNotPresent")
        limits            = merge(try(coalesce(partition.polling_agent.limits), {}), try(coalesce(var.compute_plane_defaults.polling_agent.limits), {}))
        requests          = merge(try(coalesce(partition.polling_agent.requests), {}), try(coalesce(var.compute_plane_defaults.polling_agent.requests), {}))
      }
      worker = [
        for i, worker in partition.worker :
        {
          name              = try(coalesce(worker.name), "worker-${i}")
          image             = try(coalesce(worker.image), coalesce(var.compute_plane_defaults.worker.image))
          tag               = try(coalesce(worker.tag), coalesce(var.compute_plane_defaults.worker.tag), null)
          image_pull_policy = try(coalesce(worker.image_pull_policy), coalesce(var.compute_plane_defaults.worker.image_pull_policy), "IfNotPresent")
          limits            = merge(try(coalesce(worker.limits), {}), try(coalesce(var.compute_plane_defaults.worker.limits), {}))
          requests          = merge(try(coalesce(worker.requests), {}), try(coalesce(var.compute_plane_defaults.worker.requests), {}))
        }
      ]
      # KEDA scaler
      hpa = try(coalesce(partition.hpa), coalesce(var.compute_plane_defaults.hpa), {})
    }
  }
}
