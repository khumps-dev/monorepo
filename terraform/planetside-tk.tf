locals {
  planetside_tk_name      = "planetside-tk"
  planetside_tk_namespace = "planetside"
  planetside_tk_port      = 80
}
resource "kubernetes_namespace" "planetside" {
  metadata {
    name = local.planetside_tk_namespace
  }
}

resource "kubernetes_deployment" "planetside-tk" {
  metadata {
    name      = local.planetside_tk_name
    namespace = local.planetside_tk_namespace
    labels = {
      app = local.planetside_tk_name
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app : local.planetside_tk_name
      }
    }
    template {
      metadata {
        labels = {
          app : local.planetside_tk_name
        }
      }
      spec {
        container {
          name  = "nginx"
          image = "nginx:latest"
          port {
            container_port = local.planetside_tk_port
          }
          volume_mount {
            mount_path = "/usr/share/nginx/html"
            name       = "html"
          }
        }
        volume {
          name = "html"
          persistent_volume_claim {
            claim_name = local.planetside_tk_name
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "planetside-tk" {
  wait_for_load_balancer = true
  metadata {
    name      = "http-ingress"
    namespace = local.planetside_tk_namespace
    annotations = {
      "kubernetes.io/tls-acme" = "true"
    }
  }
  spec {
    ingress_class_name = local.ingress_class_name
    tls {
      hosts = [
        "tk.khumps.dev"
      ]
      secret_name = "tk-khumps-dev-tls-acme"
    }
    rule {
      host = "tk.khumps.dev"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "planetside-tk"
              port {
                number = local.planetside_tk_port
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "planetside-tk" {
  metadata {
    name      = local.planetside_tk_name
    namespace = local.planetside_tk_namespace
  }
  spec {
    access_modes       = ["ReadOnlyMany"]
    storage_class_name = local.storage_class_name
    resources {
      requests = {
        storage : "10Mi"
      }
    }
  }
}

resource "kubernetes_service" "planetside-tk" {
  metadata {
    name      = local.planetside_tk_name
    namespace = local.planetside_tk_namespace
  }
  spec {
    selector = {
      app : local.planetside_tk_name
    }
    port {
      name = "http"
      port = local.planetside_tk_port
    }
  }
}
