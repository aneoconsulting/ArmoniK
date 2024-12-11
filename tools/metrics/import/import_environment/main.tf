resource "docker_image" "prometheus_image" {
    name= "prom/prometheus:latest"
}

resource "docker_image" "grafana_image" {
    name= "grafana/grafana"
}

resource "docker_volume" "prometheus_data" {
  name = "prometheus_data"
}

resource "docker_network" "import_env_network" {
    name = "monitoring"
    driver = "bridge"
}

resource "docker_container" "prometheus_container" {
  name  = "prometheus"
  image = docker_image.prometheus_image
  restart = "unless-stopped"
  user  = "root" # Temporarily use root to set permissions
  entrypoint = [
    "/bin/sh",
    "-c",
    "chown -R 65534:65534 /prometheus && \
     exec /bin/prometheus --config.file=/etc/prometheus/prometheus.yml \
     --storage.tsdb.path=/prometheus/ \
     --web.console.libraries=/etc/prometheus/console_libraries \
     --web.console.templates=/etc/prometheus/consoles \
     --web.enable-lifecycle"
  ]

  ports {
    internal = 9090
    external = 9090
  }

  networks_advanced {
    name = docker_network.import_env_network.name
  }

  volumes {

    container_path = "/prometheus"
    host_path = docker_volume.prometheus_data.name
  }

  volumes {
    container_path = "/etc/prometheus/prometheus.yml"
    host_path = "./configs/prometheus.yml"
  }

  depends_on = [docker_volume.prometheus_data]
}

resource "docker_container" "grafana_container" {
    name = "grafana"
    image = docker_image.grafana_image
    restart = "always"

    ports {
      internal = 3000
      external = 3000
    }

    networks_advanced {
        name = docker_network.import_env_network.name
    }

    depends_on = [docker_container.prometheus_container]
}