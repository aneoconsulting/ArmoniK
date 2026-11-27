# Object storage of ArmoniK Core: task payloads, results, and the dynamic workers' libraries. SSE-S3: with a KMS key,
# every object written is a KMS request, and the bench rates exceed the KMS request quota. The planes get their access
# from identities.tf.
module "object_storage" {
  source = "git::https://github.com/aneoconsulting/ArmoniK.Infra.git//storage/aws/s3?ref=dw/aws-charts-modules"

  name          = "${local.name}-object-storage"
  region        = var.region
  sse_algorithm = "AES256"
  tags          = local.tags
}

# S3 Express One Zone: single-digit millisecond requests from the same zone, no ramp-up of the request rate. Emptied
# on destroy, a bench deployment.
module "object_storage_express" {
  source = "git::https://github.com/aneoconsulting/ArmoniK.Infra.git//storage/aws/s3-express?ref=dw/aws-charts-modules"
  count  = var.object_storage.express ? 1 : 0

  name                 = "${local.name}-object-storage"
  availability_zone_id = var.object_storage.express_zone_id
  force_destroy        = true
}

data "aws_availability_zone" "express" {
  count   = var.object_storage.express ? 1 : 0
  zone_id = var.object_storage.express_zone_id
}

locals {
  # What Core uses: the directory bucket and its zonal endpoint, else the general purpose bucket and the regional
  # endpoint the chart derives from the region (empty endpoint)
  object_storage = var.object_storage.express ? {
    bucket   = module.object_storage_express[0].name
    endpoint = module.object_storage_express[0].endpoint_url
    } : {
    bucket   = module.object_storage.s3_bucket_name
    endpoint = ""
  }

  # Zone of the Karpenter nodes, when pinned to the one of the directory bucket
  node_zones = var.object_storage.pin_to_express_zone ? [data.aws_availability_zone.express[0].name] : null
}

# Table storage: Aurora PostgreSQL, the GetEvents streams on the writer, everything else through the RDS Proxy when
# enabled (dependencies.externalPostgresql of values/armonik.yaml)
module "database" {
  source = "git::https://github.com/aneoconsulting/ArmoniK.Infra.git//storage/aws/aurora?ref=dw/aws-charts-modules"

  name                      = local.name
  engine_version            = var.database.engine_version
  instance_class            = var.database.instance_class
  instances                 = var.database.instances
  io_optimized              = var.database.io_optimized
  serverless                = var.database.serverless
  cluster_parameters        = var.database.cluster_parameters
  proxy                     = var.database.proxy
  vpc_id                    = module.vpc.id
  subnet_ids                = module.vpc.private_subnets
  client_security_group_ids = [module.eks.node_security_group_id]
  kms_key_arn               = module.kms.key_arn

  # A bench deployment: destroyed without a snapshot, changes applied right away
  final_snapshot      = false
  deletion_protection = false
  apply_immediately   = true

  tags = local.tags
}

locals {
  # Core creates its queues itself, named after SQS__Prefix
  sqs_prefix = local.name
}
