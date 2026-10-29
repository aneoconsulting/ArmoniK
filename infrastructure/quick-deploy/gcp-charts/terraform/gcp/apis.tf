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
    "storage.googleapis.com",
    # Nothing here creates a topic: Core does at runtime
    "pubsub.googleapis.com",
  ])

  service            = each.value
  disable_on_destroy = false
}
