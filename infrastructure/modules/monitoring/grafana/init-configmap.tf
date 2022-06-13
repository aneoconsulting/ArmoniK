resource "kubernetes_config_map" "grafana_ini" {
  metadata {
    name      = "grafana-ini-configmap"
    namespace = var.namespace
  }
  data = {
    "grafana.ini" = <<-EOF
    [server]
    domain=localhost
    root_url = %(protocol)s://%(domain)s:%(http_port)s/grafana
    serve_from_sub_path = true
    [auth.anonymous]
    enabled = true
    EOF
  }
}
