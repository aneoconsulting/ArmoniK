output "keda" {
  value = {
    chart_name = helm_release.keda.name
  }
}
