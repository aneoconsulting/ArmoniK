# Use monitoring
monitoring = {
  namespace  = "armonik-monitoring"
  seq        = {
    image = "datalust/seq"
    tag   = "2021.4"
    use   = true
    node_selector = {}
  }
  grafana    = {
    image = "grafana/grafana"
    tag   = "latest"
    use   = false
  }
  prometheus = {
    image = "prom/prometheus"
    tag   = "latest"
    use   = false
  }
}


