resource "docker_image" "prometheus_image" {
    name= "prom/prometheus:latest"
}

resource "docker_image" "grafana_image" {
    name= "grafana/grafana"
}

resource "docker_image" "seq_image" {
  name = "datalust/seq"
}



resource "docker_network" "import_env_network" {
    name = "monitoring"
    driver = "bridge"
}

resource "docker_container" "prometheus_container" {
  count = length(var.prometheus_data_directory) > 0 ? 1 : 0
  name  = "prometheus"
  image = docker_image.prometheus_image.name
  restart = "unless-stopped"
  user  = "root" # Temporarily use root to set permissions
  entrypoint = [
    "/bin/sh",
    "-c",
    <<EOF
    echo "Reloaded" && \
    chown -R 65534:65534 /prometheus && \
     exec /bin/prometheus --config.file=/etc/prometheus/prometheus.yml \
     --storage.tsdb.path=/prometheus/ \
     --web.console.libraries=/etc/prometheus/console_libraries \
     --web.console.templates=/etc/prometheus/consoles \
     --web.enable-lifecycle
    EOF
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
    host_path = var.prometheus_data_directory
  }

  volumes {
    container_path = "/etc/prometheus/prometheus.yml"
    host_path = "${abspath(path.module)}/configs/prometheus.yml"
  }

}

resource "docker_container" "grafana_container" {
    count = length(var.prometheus_data_directory) > 0 ? 1 : 0
    name = "grafana"
    image = docker_image.grafana_image.name
    restart = "always"

    ports {
      internal = 3000
      external = 3000
    }

    volumes {
      container_path = "/etc/grafana/provisioning/datasource.yml"
      host_path = "${abspath(path.module)}/configs/grafana.yml"
    }

    networks_advanced {
        name = docker_network.import_env_network.name
    }

    depends_on = [docker_container.prometheus_container]
}

resource "docker_container" "seq_container" {
  name = "seq"
  image = docker_image.seq_image.name
  restart = "unless-stopped"

  ports {
    internal = 80
    external = 9080
  }

  ports {
    internal = 5341
    external = 9341
  }

  env = ["ACCEPT_EULA=Y"]
  labels {
    label = "log_id"
    value = "" #can set this label later using a variable to refresh only seq, but it might cause some confusion.. todo
  }
}

resource "docker_image" "jupyer_env_image" {
  name = "jupyer_env_image"
  build {
    context = "."
    dockerfile = "Notebook.Dockerfile"
  }
  keep_locally = true
}

resource "docker_container" "jupyter_env_container" {
  name = "jupyter"
  image = docker_image.jupyer_env_image.name 
  restart = "unless-stopped"

  ports {
    internal = 8888
    external = 8888
  }

  # add volume for database later 
  volumes {
    container_path = "/database/"
    host_path = var.database_data_directory
  }
}