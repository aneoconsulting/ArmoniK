resource "kubernetes_deployment" "s3" {
    metadata {
        annotations      = {}
        labels           = {
            "app" = local.host
        }
        name             = local.host
        namespace        = "armonik"
        #uid              = "0c5aeb55-f451-40a7-b30b-765a42dfef77"
    }

    spec {
        min_ready_seconds         = 0
        paused                    = false
        progress_deadline_seconds = 600
        replicas                  = "1"
        revision_history_limit    = 10

        selector {
            match_labels = {
                "app" = local.host
            }
        }

        strategy {
            type = "RollingUpdate"

            rolling_update {
                max_surge       = "25%"
                max_unavailable = "25%"
            }
        }

        template {
            metadata {
                annotations = {}
                labels      = {
                    "app" = local.host
                }
            }

            spec {
                automount_service_account_token  = false
                dns_policy                       = "ClusterFirst"
                enable_service_links             = false
                host_ipc                         = false
                host_network                     = false
                host_pid                         = false
                node_selector                    = {}
                restart_policy                   = "Always"
                share_process_namespace          = false
                termination_grace_period_seconds = 30

                container {
                    command                    = ["/bin/bash"]
                    args                       = [
                        "-c",
                        "mkdir -p /data/defaultbucket && minio server /data --console-address :9001"
                    ]
                    image                      = "quay.io/minio/minio"
                    image_pull_policy          = "Always"
                    name                       = local.host
                    stdin                      = false
                    stdin_once                 = false
                    termination_message_path   = "/dev/termination-log"
                    termination_message_policy = "File"
                    tty                        = false

                    env {
                        name  = "MINIO_ROOT_USER"
                        value = local.login
                    }
                    env {
                        name  = "MINIO_ROOT_PASSWORD"
                        value = local.password
                    }
                    port {
                        container_port = local.port
                        protocol       = "TCP"
                    }

                    port {
                        container_port = 9001
                        protocol       = "TCP"
                    }                    

                    resources {}
                }
            }
        }
    }

    timeouts {}
}


resource "kubernetes_service" "s3" {
    metadata {
        annotations      = {}
        labels           = {
            "app" = local.host
        }
        name             = local.host
        namespace        = "armonik"
    }

    spec {
        #cluster_ip                  = "10.43.76.96"
        #health_check_node_port      = 0
        publish_not_ready_addresses = false
        selector                    = {
            "app" = local.host
        }
        session_affinity            = "None"
        type                        = "ClusterIP"

        port {
            name        = "port${local.port}"
            #node_port   = 30900
            port        = local.port
            protocol    = "TCP"
            target_port = local.port
        }
        port {
            name        = "port90001"
            #node_port   = 30901
            port        = 9001
            protocol    = "TCP"
            target_port = 9001
        }
    }

    timeouts {}
}