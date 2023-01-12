locals{
    # minio configuration. will be also used in armonik module for setting configMap
    host ="minio"
    port = "9000"
    url = "http://${local.host}:${local.port}/"
    login = "minioadmin"
    password = "minioadmin"
}
