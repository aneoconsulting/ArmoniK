# Table storage of Core: Cloud SQL for PostgreSQL, reached from the VPC through a Private Service Connect endpoint and
# its DNS record, both created by Cloud SQL. A deleted instance keeps its name reserved for up to a week: the suffix
# lets a destroyed deployment come back.
resource "random_string" "database_suffix" {
  length  = 5
  special = false
  upper   = false
}

module "database" {
  source = "git::https://github.com/aneoconsulting/ArmoniK.Infra.git//storage/gcp/cloudsql?ref=dw/gcp-charts-deploy"

  name    = "${var.prefix}-${random_string.database_suffix.result}"
  region  = var.region
  network = module.vpc.self_link
  # The endpoint takes its IP address in the subnet of the nodes
  psc_subnets         = [module.vpc.gke_subnet_id]
  tier                = var.database.tier
  availability_type   = var.database.availability_type
  disk                = { size = var.database.disk_size }
  deletion_protection = false
  # A quick deploy: no backup to pay for
  backup = { enabled = false }
  labels = local.labels

  depends_on = [terraform_data.apis]
}

# Read by the core conf layer of the armonik release (dependencies.externalPostgresql)
resource "kubernetes_secret_v1" "postgresql" {
  metadata {
    name      = "postgresql"
    namespace = kubernetes_namespace_v1.armonik.metadata[0].name
  }

  data = {
    username = module.database.username
    password = module.database.password
  }
}

# CA that Core verifies the server certificate against, host name included
resource "kubernetes_secret_v1" "postgresql_ca" {
  metadata {
    name      = "postgresql-ca"
    namespace = kubernetes_namespace_v1.armonik.metadata[0].name
  }

  data = {
    "ca.crt" = module.database.ca_cert
  }
}
