# Object storage of ArmoniK Core: task payloads, results, and the dynamic workers' libraries
module "object_storage" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.16"

  bucket        = "${local.name}-object-storage"
  force_destroy = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  attach_deny_insecure_transport_policy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = module.kms.key_arn
      }
      # One data key per bucket instead of one KMS call per object, which would otherwise hit the
      # KMS request quota under load
      bucket_key_enabled = true
    }
  }
}

locals {
  # Core creates its queues itself, named after SQS__Prefix
  sqs_prefix = local.name
}
