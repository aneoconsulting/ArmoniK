# Use monitoring
monitoring = {
  namespace  = "armonik-monitoring"
  seq        = {
    image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/seq"
    tag   = "2021.4"
    use   = true
  }
  grafana    = {
    image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/grafana"
    tag   = "latest"
    use   = false
  }
  prometheus = {
    image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/prometheus"
    tag   = "latest"
    use   = false
  }
}


