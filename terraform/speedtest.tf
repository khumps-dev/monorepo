locals {
  speedtest_name = "speedtest"
  speedtest_port = 8080
}
resource "kubernetes_namespace" "speedtest" {
  metadata {
    name = local.speedtest_name
  }
}

resource "kubernetes_deployment" "speedtest" {
  metadata {
    name      = local.speedtest_name
    namespace = local.speedtest_name
    labels = {
      app = local.speedtest_name
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app : local.speedtest_name
      }
    }
    template {
      metadata {
        labels = {
          app : local.speedtest_name
        }
      }
      spec {
        container {
          name  = "speedtest"
          image = "openspeedtest/latest:latest"
          port {
            container_port = local.speedtest_port
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "speedtest" {
  metadata {
    name      = local.speedtest_name
    namespace = local.speedtest_name
  }
  spec {
    selector = {
      app : local.speedtest_name
    }
    port {
      name = "http"
      port = local.speedtest_port
    }
  }
}
