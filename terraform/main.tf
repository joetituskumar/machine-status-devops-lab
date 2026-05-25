terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "manufacturing" {
  metadata {
    name = "manufacturing"

    labels = {
      environment = "home-lab"
      owner       = "joel"
      project     = "machine-status-api"
    }
  }
}

resource "kubernetes_config_map" "machine_api_config" {
  metadata {
    name      = "machine-api-config"
    namespace = kubernetes_namespace.manufacturing.metadata[0].name
  }

  data = {
    APP_ENV     = "home-lab"
    APP_VERSION = "1.0.0"
  }
}
