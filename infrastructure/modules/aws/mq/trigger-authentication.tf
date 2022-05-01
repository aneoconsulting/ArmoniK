resource "kubectl_manifest" "activemq_trigger_authentication" {
  yaml_body = <<YAML
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: trigger-auth-activemq
  namespace: ${var.namespace}
spec:
  secretTargetRef:
  - parameter: username
    name: ${kubernetes_secret.activemq_user.metadata[0].name}
    key: username
  - parameter: password
    name: ${kubernetes_secret.activemq_user.metadata[0].name}
    key: password
YAML
}