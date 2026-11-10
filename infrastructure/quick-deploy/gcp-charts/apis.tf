# APIs of the project, which a new project has disabled. Never disabled on destroy: other deployments of the
# project may use them.
resource "google_project_service" "apis" {
  for_each = toset([
    # Read by the modules (google_project data source)
    "cloudresourcemanager.googleapis.com",
    # Network, Cloud NAT, load balancer of the ingress
    "compute.googleapis.com",
    "container.googleapis.com",
    # Node service account and IAM bindings
    "iam.googleapis.com",
    # Pull-through caches and the upstream credentials they read
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "storage.googleapis.com",
    # Table storage, and the service connection policy of its Private Service Connect endpoint (database.tf)
    "sqladmin.googleapis.com",
    "networkconnectivity.googleapis.com",
    # Cloud SQL metrics read by Grafana (monitoring.tf)
    "monitoring.googleapis.com",
    # Nothing here creates a topic: Core does at runtime
    "pubsub.googleapis.com",
  ])

  service            = each.value
  disable_on_destroy = false
}

# What the modules wait for, so that a new project enables the APIs before them.
#
# Adding an API to the list above: apply it alone first (terraform apply -target=google_project_service.apis). A
# module-level depends_on defers every data source of the module to the apply as soon as one of its dependencies,
# even indirect like this one, has pending changes: the project and region they read become unknown, and every
# resource built from them would be replaced (the network, the caches, the bucket, the database).
resource "terraform_data" "apis" {
  depends_on = [google_project_service.apis]
}
