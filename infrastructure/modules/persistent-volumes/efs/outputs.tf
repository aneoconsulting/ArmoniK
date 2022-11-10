output "pvc_name" {
  description = "Persistent volume claim name"
  value       = kubernetes_persistent_volume_claim.efs_pvc.metadata.0.name
}

output "pvc_namespace" {
  description = "Persistent volume claim namespace"
  value       = kubernetes_persistent_volume_claim.efs_pvc.metadata.0.namespace
}