# MongoDB
module "mongodb" {
  source      = "../../../modules/onpremise-storage/mongodb"
  namespace   = var.namespace
  working_dir = "${path.root}/../../.."
  mongodb     = {
    image         = var.mongodb.image
    tag           = var.mongodb.tag
    node_selector = var.mongodb.node_selector
  }
}