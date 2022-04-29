# Envvars
locals {
  armonik_conf = <<-EOF
    map $http_upgrade $connection_upgrade {
      default upgrade;
      '' close;
    }
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        ssl_certificate     /ingress/ingress.crt;
        ssl_certificate_key /ingress/ingress.key;
        ssl_verify_client off;
        
        location / {
            grpc_pass grpc://${local.control_plane_endpoints.ip}:${local.control_plane_endpoints.port};

        }
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
    }
    EOF
  nginx_conf = <<EOF
    user  nginx;
    worker_processes  auto;

    error_log  stderr debug;
    pid        /var/run/nginx.pid;


    events {
        worker_connections  1024;
    }


    http {
        include       /etc/nginx/mime.types;
        default_type  application/octet-stream;

        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';

        access_log  /var/log/nginx/access.log  main;

        sendfile        on;
        #tcp_nopush     on;

        keepalive_timeout  65;

        #gzip  on;

        include /etc/nginx/conf.d/*.conf;
    }
    EOF
}

resource "kubernetes_config_map" "ingress" {
  metadata {
    name      = "ingress-nginx"
    namespace = var.namespace
  }
  data = {
    "armonik.conf" = local.armonik_conf
    "nginx.conf" = local.nginx_conf
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
