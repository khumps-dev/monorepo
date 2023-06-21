locals {
  unifi_name = "unifi"
}
resource "kubernetes_namespace" "unifi" {
  metadata {
    name = local.unifi_name
  }
}

resource "kubernetes_deployment" "unifi" {
  metadata {
    name      = local.unifi_name
    namespace = local.unifi_name
    labels = {
      app = local.unifi_name
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app : local.unifi_name
      }
    }
    template {
      metadata {
        labels = {
          app : local.unifi_name
        }
      }
      spec {
        container {
          name  = "controller"
          image = "lscr.io/linuxserver/unifi-controller:7.3.76"
          env {
            name  = "PUID"
            value = "1000"
          }
          env {
            name  = "PGID"
            value = "1004"
          }
          volume_mount {
            mount_path = "/config"
            name       = "config"
          }
        }
        volume {
          name = "config"
          nfs {
            path   = "/mnt/Main/kevin/unifi-controller"
            server = local.nfs_host
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "unifi" {
  wait_for_load_balancer = true
  metadata {
    name      = "http-ingress"
    namespace = local.unifi_name
    annotations = {
      "nginx.ingress.kubernetes.io/backend-protocol" : "HTTPS"
      "kubernetes.io/tls-acme" = "true"
    }
  }
  spec {
    ingress_class_name = "public"
    tls {
      hosts = [
        "unifi.internal.khumps.dev"
      ]
      secret_name = "unifi-internal-khumps-dev-tls-acme"
    }
    rule {
      host = "unifi.internal.khumps.dev"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "unifi"
              port {
                number = 8443
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "unifi" {
  metadata {
    name      = local.unifi_name
    namespace = local.unifi_name
  }
  spec {
    selector = {
      app : local.unifi_name
    }
    port {
      port     = 1900
      name     = "l2-discovery"
      protocol = "UDP"
    }
    port {
      port     = 3478
      name     = "stun"
      protocol = "UDP"
    }
    port {
      port = 8080
      name = "devices"
    }
    port {
      port = 8443
      name = "web"
    }
    port {
      port     = 10001
      name     = "discovery"
      protocol = "UDP"
    }
  }
}
