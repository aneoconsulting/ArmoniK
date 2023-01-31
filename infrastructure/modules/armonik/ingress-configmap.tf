# Envvars
locals {
  armonik_conf = <<EOF
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}
%{if var.ingress != null ? var.ingress.mtls : false~}
    map $ssl_client_s_dn $ssl_client_s_dn_cn {
        default "";
        ~CN=(?<CN>[^,/]+) $CN;
    }
%{endif~}
server {
%{if var.ingress != null ? var.ingress.tls : false~}
    listen 8443 ssl http2;
    listen [::]:8443 ssl http2;
    listen 9443 ssl http2;
    listen [::]:9443 ssl http2;
    ssl_certificate     /ingress/ingress.crt;
    ssl_certificate_key /ingress/ingress.key;
%{if var.ingress.mtls~}
    ssl_verify_client on;
    ssl_client_certificate /ingressclient/ca.pem;
%{else~}
    ssl_verify_client off;
    proxy_hide_header X-Certificate-Client-CN;
    proxy_hide_header X-Certificate-Client-Fingerprint;
%{endif~}
    ssl_protocols TLSv1.3;
    ssl_ciphers EECDH+AESGCM:EECDH+AES256;
%{else~}
    listen 8080;
    listen [::]:8080;
    listen 9080 http2;
    listen [::]:9080 http2;
%{endif~}

    sendfile on;

    location = / {
        rewrite ^ $scheme://$http_host/admin/ permanent;
    }
    location = /admin {
        rewrite ^ $scheme://$http_host/admin/ permanent;
    }
    location /admin/ {
        proxy_pass ${local.admin_gui_url};
    }


    location ~* ^/armonik\. {
%{if var.ingress != null ? var.ingress.mtls : false~}
        grpc_set_header X-Certificate-Client-CN $ssl_client_s_dn_cn;
        grpc_set_header X-Certificate-Client-Fingerprint $ssl_client_fingerprint;
%{endif~}
        grpc_pass grpc://${local.control_plane_endpoints.ip}:${local.control_plane_endpoints.port};

        # Apparently, multiple chunks in a grpc stream is counted has a single body
        # So disable the limit
        client_max_body_size 0;

        # add a timeout of 1 month to avoid grpc exception for long task
        # TODO: find better configuration
        proxy_read_timeout 30d;
        proxy_send_timeout 1d;
        grpc_read_timeout 30d;
        grpc_send_timeout 1d;
    }

%{if local.seq_web_url != ""~}
    location = /seq {
        rewrite ^ $scheme://$http_host/seq/ permanent;
    }
    location /seq/ {
%{if var.ingress != null ? var.ingress.mtls : false~}
        proxy_set_header X-Certificate-Client-CN $ssl_client_s_dn_cn;
        proxy_set_header X-Certificate-Client-Fingerprint $ssl_client_fingerprint;
%{endif~}
        proxy_set_header Host $http_host;
        proxy_set_header Accept-Encoding "";
        rewrite  ^/seq/(.*)  /$1 break;
        proxy_pass ${local.seq_web_url}/;
        sub_filter '<head>' '<head><base href="$${scheme}://$${http_host}/seq/">';
        sub_filter_once on;
        proxy_hide_header content-security-policy;
    }
%{endif~}
%{if local.grafana_url != ""~}
    location = /grafana {
        rewrite ^ $scheme://$http_host/grafana/ permanent;
    }
    location /grafana/ {
%{if var.ingress != null ? var.ingress.mtls : false~}
        proxy_set_header X-Certificate-Client-CN $ssl_client_s_dn_cn;
        proxy_set_header X-Certificate-Client-Fingerprint $ssl_client_fingerprint;
%{endif~}
        proxy_set_header Host $http_host;
        proxy_pass ${local.grafana_url}/;
        sub_filter '<head>' '<head><base href="$${scheme}://$${http_host}/grafana/">';
        sub_filter_once on;
        proxy_intercept_errors on;
        error_page 301 302 307 =302 $${scheme}://$${http_host}$${upstream_http_location};
    }
    location /grafana/api/live {
        rewrite  ^/grafana/(.*)  /$1 break;
%{if var.ingress != null ? var.ingress.mtls : false~}
        proxy_set_header X-Certificate-Client-CN $ssl_client_s_dn_cn;
        proxy_set_header X-Certificate-Client-Fingerprint $ssl_client_fingerprint;
%{endif~}
%{if var.ingress != null ? var.ingress.tls : false~}
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
%{endif~}
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_pass ${local.grafana_url}/;
    }
%{endif~}
}
EOF
}

resource "kubernetes_config_map" "ingress" {
  count = (var.ingress != null ? 1 : 0)
  metadata {
    name      = "ingress-nginx"
    namespace = var.namespace
  }
  data = {
    "armonik.conf" = local.armonik_conf
  }
}

resource "local_file" "ingress_conf_file" {
  count           = (var.ingress != null ? 1 : 0)
  content         = local.armonik_conf
  filename        = "${path.root}/generated/configmaps/ingress/armonik.conf"
  file_permission = "0644"
}
