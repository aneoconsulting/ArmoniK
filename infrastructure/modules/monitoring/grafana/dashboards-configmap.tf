resource "kubernetes_config_map" "dashboards_json_config" {
  metadata {
    name      = "dashboards-json-configmap"
    namespace = var.namespace
  }
  data = {
    "dashboard-armonik.json" = "${file("${path.module}/dashboard-armonik.json")}"
  }
}


locals {
  dashboards_config = <<EOF
apiVersion: 1

providers:
  - name: 'ArmoniK local Provider'
    # <int> Org id. Default to 1
    orgId: 1
    # <string> name of the dashboard folder.
    folder: 'ArmoniK'
    # <string> folder UID. will be automatically generated if not specified
    folderUid: ''
    # <string> provider type. Default to 'file'
    type: file
    # <bool> disable dashboard deletion
    disableDeletion: false
    # <int> how often Grafana will scan for changed dashboards
    updateIntervalSeconds: 10
    # <bool> allow updating provisioned dashboards from the UI
    allowUiUpdates: true
    options:
      # <string, required> path to dashboard files on disk. Required when using the 'file' type
      path: /var/lib/grafana/dashboards
      # <bool> use folder names from filesystem to create folders in Grafana
      foldersFromFilesStructure: true
EOF
}

# configmap with all the variables
resource "kubernetes_config_map" "dashboards_config" {
  metadata {
    name      = "dashboards-configmap"
    namespace = var.namespace
  }
  data = {
    "dashboards.yml" = local.dashboards_config
  }
}

resource "local_file" "dashboards_config_file" {
  content  = local.dashboards_config
  filename = "${path.root}/generated/configmaps/dashboards-grafana.yml"
}