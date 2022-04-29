# Envvars
locals {
  armonik_conf = <<-EOF
    upstream controlplane{
        server ${local.control_plane_endpoints.ip}:${local.control_plane_endpoints.port};
        keepalive 15;
    }
    map $http_upgrade $connection_upgrade {
      default upgrade;
      '' close;
    }
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        ssl_client_certificate /ingress/chain.pem;
        ssl_certificate     /ingress/ingress.pem;
        ssl_certificate_key /ingress/ingress.key;
        
        location /seq {
            proxy_set_header        Host $http_host;
            proxy_set_header Accept-Encoding "";
            rewrite  ^/seq/(.*)  /$1 break;
            proxy_pass ${local.seq_web_url}/;
            sub_filter '<head>' '<head><base href="$${scheme}://$${http_host}/seq/">';
            sub_filter_once on;
            proxy_hide_header content-security-policy;
        }
        location /grafana {
            rewrite ^ $scheme://$http_host/grafana/ permanent;
        }
        location /grafana/ {
            proxy_set_header Host $http_host;
            proxy_pass ${local.grafana_url}/;
            sub_filter '<head>' '<head><base href="$${scheme}://$${http_host}/grafana/">';
            sub_filter_once on;
            proxy_intercept_errors on;
            error_page 301 302 307 =302 $${scheme}://$${http_host}$${upstream_http_location};
        }
        location /grafana/api/live {
            rewrite  ^/grafana/(.*)  /$1 break;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $http_host;
            proxy_pass ${local.grafana_url}/;
        }
        
        location / {
            grpc_pass controlplane;
        }
    }
    EOF
  /*nginx_conf = <<EOF
    worker_processes auto;
    pid /run/nginx.pid;
    events {
        worker_connections 1024;
    }
    http {
        sendfile on;
        include /etc/nginx/mime.types;
        default_type application/octet-stream;
        include /etc/nginx/conf.d/armonik.conf;
    }
    EOF*/
}

resource "kubernetes_config_map" "ingress" {
  metadata {
    name      = "ingress-nginx"
    namespace = var.namespace
  }
  data = {
    "armonik.conf" = local.armonik_conf
    #"nginx.conf" = local.nginx_conf
  }
}

resource "local_file" "ingress_conf_file" {
  content  = local.armonik_conf
  filename = "${path.root}/generated/configmaps/armonik.conf"
}

/*resource "local_file" "nginx_conf_file" {
  content  = local.nginx_conf
  filename = "${path.root}/generated/configmaps/nginx.conf"
}*/
