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
    strategy {
      type = "Recreate"
    }
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
          image = "lscr.io/linuxserver/unifi-network-application:7.5.174"
          env {
            name  = "PUID"
            value = "1000"
          }
          env {
            name  = "PGID"
            value = "1004"
          }
          env {
            name  = "MONGO_USER"
            value = "unifi"
          }
          env {
            name  = "MONGO_PASS"
            value = "unifimongopass"
          }
          env {
            name  = "MONGO_HOST"
            value = "localhost"
          }
          env {
            name  = "MONGO_PORT"
            value = "27017"
          }
          env {
            name  = "MONGO_DBNAME"
            value = "unifi"
          }
          volume_mount {
            mount_path = "/config"
            name       = "unifi-config"
          }
        }
        container {
          name  = "mongodb"
          image = "mongo:6.0"
          volume_mount {
            mount_path = "/data/db"
            name       = "mongodb-config"
          }
          volume_mount {
            mount_path = "/docker-entrypoint-initdb.d/init-mongo.js"
            name       = "mongodb-init"
            sub_path   = "init-mongo.js"
            read_only  = true
          }
        }

        volume {
          name = "unifi-config"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.unifi.metadata[0].name
          }
        }
        volume {
          name = "mongodb-config"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.unifi-mongodb.metadata[0].name
          }
        }
        volume {
          name = "mongodb-init"
          config_map {
            name = kubernetes_config_map_v1.unifi-mongodb-init.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "unifi" {
  metadata {
    name      = local.unifi_name
    namespace = local.unifi_name
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = local.longhorn_storage_class_name
    resources {
      requests = {
        storage : "5Gi"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "unifi-mongodb" {
  metadata {
    name      = "${local.unifi_name}-mongodb"
    namespace = local.unifi_name
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = local.longhorn_storage_class_name
    resources {
      requests = {
        storage : "5Gi"
      }
    }
  }
}

resource "kubernetes_config_map_v1" "unifi-mongodb-init" {
  metadata {
    name      = "mongodb-init"
    namespace = local.unifi_name
  }
  data = {
    "init-mongo.js" : "db.getSiblingDB(\"unifi\").createUser({user: \"unifi\", pwd: \"unifimongopass\", roles: [{role: \"dbOwner\", db: \"unifi\"}, {role: \"dbOwner\", db: \"unifi_stat\"}]});"
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
