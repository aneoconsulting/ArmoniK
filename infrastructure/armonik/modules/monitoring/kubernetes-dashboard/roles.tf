resource "kubernetes_config_map" "kubernetes_dashboard_settings" {
  metadata {
    name      = "kubernetes-dashboard-settings"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      type    = "configmap"
      service = "kubernetes-dashboard"
    }
  }
}

resource "kubernetes_role" "kubernetes_dashboard" {
  metadata {
    name      = "kubernetes-dashboard"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      type    = "role"
      service = "kubernetes-dashboard"
    }
  }
  rule {
    # Allow Dashboard to get, update and delete Dashboard exclusive secrets.
    api_groups     = [""]
    resources      = ["secrets"]
    resource_names = [
      kubernetes_secret.kubernetes_dashboard_key_holder.metadata.0.name,
      kubernetes_secret.kubernetes_dashboard_certs.metadata.0.name,
      kubernetes_secret.kubernetes_dashboard_csrf.metadata.0.name
    ]
    verbs          = [
      "get",
      "update",
      "delete"
    ]
  }
  rule {
    # Allow Dashboard to get and update 'kubernetes-dashboard-settings' config map.
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = [kubernetes_config_map.kubernetes_dashboard_settings.metadata.0.name]
    verbs          = [
      "get",
      "update"
    ]
  }
  rule {
    # Allow Dashboard to get metrics.
    api_groups     = [""]
    resources      = ["services"]
    resource_names = [
      "heapster",
      kubernetes_service.dashboard_metrics_scraper.metadata.0.name
    ]
    verbs          = ["proxy"]
  }
  rule {
    api_groups     = [""]
    resources      = ["services/proxy"]
    resource_names = [
      "heapster",
      "http:heapster:",
      "https:heapster:",
      kubernetes_service.dashboard_metrics_scraper.metadata.0.name,
      "http:${kubernetes_service.dashboard_metrics_scraper.metadata.0.name}"
    ]
    verbs          = ["get"]
  }
}

resource "kubernetes_cluster_role" "kubernetes_dashboard" {
  metadata {
    name   = "kubernetes-dashboard"
    labels = {
      app     = "armonik"
      type    = "role"
      service = "kubernetes-dashboard"
    }
  }
  rule {
    # Allow Metrics Scraper to get metrics from the Metrics server
    api_groups = ["metrics.k8s.io"]
    resources  = [
      "pods",
      "nodes"
    ]
    verbs      = [
      "get",
      "list",
      "watch"
    ]
  }
}

resource "kubernetes_role_binding" "kubernetes_dashboard" {
  metadata {
    name      = "kubernetes-dashboard"
    namespace = var.namespace
    labels    = {
      app     = "armonik"
      type    = "role"
      service = "kubernetes-dashboard"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.kubernetes_dashboard.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = data.kubernetes_service_account.kubernetes_dashboard_service_account.metadata.0.name
    namespace = var.namespace
  }
}

resource "kubernetes_cluster_role_binding" "kubernetes_dashboard" {
  metadata {
    name   = "kubernetes-dashboard"
    labels = {
      app     = "armonik"
      type    = "role"
      service = "kubernetes-dashboard"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.kubernetes_dashboard.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = data.kubernetes_service_account.kubernetes_dashboard_service_account.metadata.0.name
    namespace = var.namespace
  }
}
