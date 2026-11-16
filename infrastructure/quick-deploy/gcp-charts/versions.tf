terraform {
  # Write-only attributes (secret_data_wo of the registry credentials)
  required_version = ">= 1.11"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.9"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 8.9"
    }
    # Same major as the ArmoniK.Infra modules (< 3.0.0)
    helm = {
      source = "hashicorp/helm"
      # 3.x embeds Helm >= 3.18: Helm 3.15 of the 2.x line ignores a null over a subchart default (the partitions
      # kept the chart's idleReplicaCount of 0)
      version = ">= 3.1, < 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}
