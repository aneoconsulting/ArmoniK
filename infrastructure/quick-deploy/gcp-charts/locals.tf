data "google_client_openid_userinfo" "current" {}

locals {
  labels = {
    application = "armonik"
    prefix      = var.prefix
    # Label values only allow lowercase letters, digits, "_" and "-"
    created_by = replace(lower(split("@", data.google_client_openid_userinfo.current.email)[0]), "/[^a-z0-9_-]/", "_")
  }

  namespaces = {
    armonik   = "armonik"
    operators = "operators"
  }

  # Kubernetes service accounts of the ArmoniK charts, set by name in values/armonik.yaml: the IAM roles of
  # identities.tf are bound to these names
  service_accounts = {
    control_plane = "armonik-control-plane"
    compute_plane = "armonik-compute-plane"
  }
}
