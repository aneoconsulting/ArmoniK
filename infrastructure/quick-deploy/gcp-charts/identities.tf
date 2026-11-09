# Workload Identity Federation: the roles go to the Kubernetes service accounts of the control plane and of the
# compute plane (polling agents) themselves, no GCP service account. The charts create the Kubernetes service
# accounts (create_service_account = false), which can come after the roles.
#
# Pub/Sub on the project: Core creates its topics (<prefix>-<partition>) and subscriptions itself when they do not
# exist, so they cannot be granted one by one. The bucket roles are in storage.tf.
module "service_accounts" {
  source   = "git::https://github.com/aneoconsulting/ArmoniK.Infra.git//service-account/gcp?ref=dw/gcp-charts-deploy"
  for_each = local.service_accounts

  name                   = each.value
  kubernetes_namespace   = local.namespaces.armonik
  roles                  = ["roles/pubsub.editor"]
  create_service_account = false
  iam_service_account    = false

  # No depends_on on the APIs: it would defer the read of the project number to the apply, and the members, keys of
  # the bucket role bindings (storage.tf), must be known at plan time
}
