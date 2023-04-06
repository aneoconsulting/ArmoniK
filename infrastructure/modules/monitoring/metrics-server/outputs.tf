output "metrics_server" {
  value = {
    chart_name = helm_release.metrics_server.name
  }
}
