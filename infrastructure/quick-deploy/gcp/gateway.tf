resource "google_compute_subnetwork" "proxy" {
  name          = "${local.prefix}-proxy"
  network       = module.vpc.id
  region        = var.region
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
  ip_cidr_range = "10.125.0.0/16"
}

resource "kubectl_manifest" "gateway" {
  yaml_body  = <<-EOT
    apiVersion: gateway.networking.k8s.io/v1
    kind: Gateway
    metadata:
      name: ${local.prefix}-gw
      namespace: ${local.namespace}
    spec:
      gatewayClassName: gke-l7-regional-external-managed
      listeners:
        - name: http
          protocol: HTTP
          port: 80
          allowedRoutes:
            kinds:
              - kind: HTTPRoute
        #- name: https
        #  protocol: HTTPS
        #  port: 443
        #  tls:
        #    mode: Terminate
        #    certificateRefs:
        #      - kind: Secret
        #        name: armonik-tls
        #  allowedRoutes:
        #    kinds:
        #      - kind: HTTPRoute
  EOT
  depends_on = [module.gke]
}


resource "kubectl_manifest" "route" {
  yaml_body = <<-EOT
    apiVersion: gateway.networking.k8s.io/v1
    kind: HTTPRoute
    metadata:
      name: ${local.prefix}-gw-http
      namespace: ${local.namespace}
    spec:
      parentRefs:
        - name: ${local.prefix}-gw
      rules:
        - matches:
            - path: { type: PathPrefix, value: /armonik.api.grpc.v1.submitter.Submitter }
            - path: { type: PathPrefix, value: /armonik.api.grpc.v1.tasks.Tasks }
            - path: { type: PathPrefix, value: /armonik.api.grpc.v1.sessions.Sessions }
            - path: { type: PathPrefix, value: /armonik.api.grpc.v1.results.Results }
            - path: { type: PathPrefix, value: /armonik.api.grpc.v1.applications.Applications }
            - path: { type: PathPrefix, value: /armonik.api.grpc.v1.partitions.Partitions }
            - path: { type: PathPrefix, value: /armonik.api.grpc.v1.events.Events }
            - path: { type: PathPrefix, value: /armonik.api.grpc.v1.auth.Authentication }
            - path: { type: PathPrefix, value: /armonik.api.grpc.v1.versions.Versions }
            - path: { type: PathPrefix, value: /armonik.api.grpc.v1.health_checks.HealthChecks }
            - path: { type: PathPrefix, value: /grpc.health.v1.Health }       # standard gRPC health
            - path: { type: PathPrefix, value: /grpc.reflection.v1.ServerReflection }  # if you use reflection
          backendRefs:
            - name: control-plane
              port: 5001
        - backendRefs:
            - name: nginx
              port: 5001
  EOT

  depends_on = [kubectl_manifest.gateway, module.armonik]
}

resource "kubectl_manifest" "hc-nginx" {
  yaml_body = <<-EOT
    apiVersion: networking.gke.io/v1
    kind: HealthCheckPolicy
    metadata:
      name: ${local.prefix}-nginx-http-hc
      namespace: ${local.namespace}
    spec:
      default:
        config:
          type: HTTP
          httpHealthCheck:
            port: 9080
            requestPath: /admin/en/ # adjust to a real 200 path; avoid /
      targetRef:
        group: ""
        kind: Service
        name: nginx
  EOT

  depends_on = [module.armonik]
}

resource "kubectl_manifest" "hc-control-plane" {
  yaml_body = <<-EOT
    apiVersion: networking.gke.io/v1
    kind: HealthCheckPolicy
    metadata:
      name: ${local.prefix}-control-plane-http-hc
      namespace: ${local.namespace}
    spec:
      default:
        config:
          type: TCP
          tcpHealthCheck:
            port: 1080
      targetRef:
        group: ""
        kind: Service
        name: control-plane
  EOT

  depends_on = [module.armonik]
}

# resource "kubectl_manifest" "grpc-timeout" {
#   yaml_body = <<-EOT
#     apiVersion: networking.gke.io/v1
#     kind: GCPBackendPolicy
#     metadata:
#       name: ${local.prefix}-grpc-timeout
#       namespace: ${local.namespace}
#     spec:
#       default:
#         timeoutSec: 864000 # 30 days
#       targetRef:
#         group: ""
#         kind: Service
#         name: control-plane
#   EOT

#   depends_on = [module.armonik]
# }
