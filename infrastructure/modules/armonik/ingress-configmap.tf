# Envvars
locals {
  armonik_conf = <<EOF
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}
server {
%{ if var.ingress != null ? var.ingress.tls : false ~}
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    ssl_certificate     /ingress/ingress.crt;
    ssl_certificate_key /ingress/ingress.key;
%{   if var.ingress.mtls ~}
    ssl_verify_client on;
    ssl_client_certificate /ingressclient/ca.pem;
%{   else ~}
    ssl_verify_client off;
%{   endif ~}
%{ else ~}
    listen 80;
    listen 81 http2;
    listen [::]:80;
    listen [::]:81 http2;
%{ endif ~}
    
    location / {
        grpc_pass grpc://${local.control_plane_endpoints.ip}:${local.control_plane_endpoints.port};
    }
%{ if local.seq_web_url != "" ~}
    location /seq {
        proxy_set_header        Host $http_host;
        proxy_set_header Accept-Encoding "";
        rewrite  ^/seq/(.*)  /$1 break;
        proxy_pass ${local.seq_web_url}/;
        sub_filter '<head>' '<head><base href="$${scheme}://$${http_host}/seq/">';
        sub_filter_once on;
        proxy_hide_header content-security-policy;
    }
%{ endif ~}
%{ if local.grafana_url != "" ~}
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
%{ if var.ingress != null ? var.ingress.tls : false ~}
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
%{ endif ~}
        proxy_set_header Host $http_host;
        proxy_pass ${local.grafana_url}/;
    }
%{ endif ~}
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
  }
}

resource "local_file" "ingress_conf_file" {
  content  = local.armonik_conf
  filename = "${path.root}/generated/configmaps/armonik.conf"

  file_permission = "0644"
}
